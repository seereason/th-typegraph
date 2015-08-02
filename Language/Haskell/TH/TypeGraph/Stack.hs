-- | The HasStack monad used in MIMO to construct lenses that look
-- deep into a record type.  However, it does not involve the Path
-- type mechanism, and is unaware of View instances and other things
-- that modify the type graph.  Lets see how it adapts.
{-# LANGUAGE CPP #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -Wall #-}
module Language.Haskell.TH.TypeGraph.Stack
    ( StackElement(..)
    , prettyStack
    , foldField
      -- * Stack+instance map monad
    , HasStack
    , StackT
    , execStackT
    , withStack
    , push
      -- * Stack operations
    , stackAccessor
    , makeLenses'
    , traceIndented
    ) where

import Control.Applicative
import Control.Category ((.))
import Control.Lens (iso, Lens', lens, set, view)
import Control.Monad.Reader (ReaderT, runReaderT {-, ask, local-})
import Control.Monad.Trans (lift)
import Control.Monad.Writer (WriterT, execWriterT, tell)
import Data.Char (toUpper)
import Data.Generics (Data, Typeable)
import Data.Map as Map (keys)
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import Debug.Trace (trace)
import Language.Haskell.Exts.Syntax ()
import Language.Haskell.TH
import Language.Haskell.TH.Desugar (DsMonad)
import Language.Haskell.TH.Instances ()
import Language.Haskell.TH.Syntax hiding (lift)
import Language.Haskell.TH.TypeGraph.Edges (GraphEdges, simpleEdges, typeGraphEdges)
import Language.Haskell.TH.TypeGraph.Expand (E(E), ExpandMap)
import Control.Monad.State.Extra (MonadState)
import Control.Monad.Reader.Extra (MonadReader(ask, local))
import Language.Haskell.TH.TypeGraph.Prelude (constructorName)
import Language.Haskell.TH.TypeGraph.Shape (FieldType(..), fName, fType, constructorFieldTypes)
import Language.Haskell.TH.TypeGraph.TypeInfo (makeTypeInfo)
import Language.Haskell.TH.TypeGraph.Vertex (etype, TGV)
import Prelude hiding ((.))

-- | The information required to extact a field value from a value.
-- We keep a stack of these as we traverse a declaration.  Generally,
-- we only need the field names.
data StackElement = StackElement FieldType Con Dec deriving (Eq, Show, Data, Typeable)

type HasStack = MonadReader [StackElement]

withStack :: (Monad m, MonadReader [StackElement] m) => ([StackElement] -> m a) -> m a
withStack f = ask >>= f

push :: MonadReader [StackElement] m => FieldType -> Con -> Dec -> m a -> m a
push fld con dec = local (\stk -> StackElement fld con dec : stk)

traceIndented :: MonadReader [StackElement] m => String -> m ()
traceIndented s = withStack $ \stk -> trace (replicate (length stk) ' ' ++ s) (return ())

prettyStack :: [StackElement] -> String
prettyStack = prettyStack' . reverse
    where
      prettyStack' :: [StackElement] -> String
      prettyStack' [] = "(empty)"
      prettyStack' (x : xs) = "[" ++ prettyElt x ++ prettyTail xs ++ "]"
      prettyTail [] = ""
      prettyTail (x : xs) = " → " ++ prettyElt x ++ prettyTail xs
      prettyElt (StackElement fld con dec) = prettyDec dec ++ ":" ++ prettyCon con ++ "." ++ pprint fld
      prettyDec (TySynD _ _ typ) = prettyType typ
      prettyDec (NewtypeD _ name _ _ _) = nameBase name
      prettyDec (DataD _ name _ _ _) = nameBase name
      prettyDec dec = error $ "prettyStack: " ++ show dec
      prettyCon = nameBase . constructorName
      prettyType (AppT t1 t2) = "((" ++ prettyType t1 ++ ") (" ++ prettyType t2 ++ "))"
      prettyType (ConT name) = nameBase name
      prettyType typ = "(" ++ show typ ++ ")"

-- | Push the stack and process the field.
foldField :: MonadReader [StackElement] m => (FieldType -> m r) -> Dec -> Con -> FieldType -> m r
foldField doField dec con fld = push fld con dec $ doField fld

type StackT m = ReaderT [StackElement] m

execStackT :: Monad m => StackT m a -> m a
execStackT action = runReaderT action []

-- | Re-implementation of stack accessor in terms of stackLens
stackAccessor :: (Quasi m, MonadReader [StackElement] m) => ExpQ -> Type -> m Exp
stackAccessor value typ0 =
    withStack f
    where
      f [] = runQ value
      f stk = do
        lns <- runQ $ stackLens stk
        Just typ <- stackType
        runQ [| view $(pure lns) $value :: $(pure typ) |]

stackType :: MonadReader [StackElement] m => m (Maybe Type)
stackType =
    withStack (return . f)
    where
      f [] = Nothing
      f (StackElement fld _ _ : _) = Just (fType fld)

-- | Return an expression of a lens for the value described by the
-- stack.
stackLens :: [StackElement] -> Q Exp
stackLens [] = [| iso id id |]
stackLens xs = mapM fieldLens xs >>= foldl1 (\ a b -> [|$b . $a|]) . map return

nthLens :: Int -> Lens' [a] a
nthLens n = lens (\ xs -> xs !! n) (\ xs x -> take (n - 1) xs ++ [x] ++ drop n xs)

-- | Generate a lens to access a field, as represented by the
-- StackElement type.
fieldLens :: StackElement -> Q Exp
fieldLens e@(StackElement fld con _) =
    do lns <-
           case fName fld of
              Right fieldName ->
                  -- Use the field name to build an accessor
                  let lensName = lensNamer (nameBase fieldName) in
                  lookupValueName lensName >>= maybe (error ("fieldLensName - missing lens: " ++ lensName)) varE
              Left fieldPos ->
                  -- Build a pattern expression to extract the field
                  do cname <- lookupValueName (nameBase $ constructorName con) >>= return . fromMaybe (error $ "fieldLens: " ++ show e)
                     f <- newName "f"
                     let n = length $ constructorFieldTypes con
                     as <- mapM newName (map (\ p -> "_a" ++ show p) [1..n])
                     [| lens -- \ (Con _ _ _ x _ _) -> x
                             $(lamE [conP cname (set (nthLens fieldPos) (varP f) (repeat wildP))] [| $(varE f) :: $(pure (fType fld)) |])
                             -- \ x (Con a b c _ d e) -> Con a b c x d e
                             $(lamE [conP cname (map varP as), varP f] (foldl appE (conE cname) (set (nthLens fieldPos) (varE f) (map varE as)))) |]
       [| $(pure lns) {- :: Lens $(pure top) $(pure (fType fld)) -} |]

-- | Generate lenses to access the fields of the row types.  Like
-- Control.Lens.TH.makeLenses, but makes lenses for every field, and
-- instead of removing the prefix '_' to form the lens name it adds
-- the prefix "lens" and capitalizes the first letter of the field.
-- The only reason for this function is backwards compatibility, the
-- fields should be changed so they begin with _ and the regular
-- makeLenses should be used.
makeLenses' :: forall m. (DsMonad m, MonadState ExpandMap m) => (Type -> m (Set Type)) -> [Name] -> m [Dec]
makeLenses' extraTypes typeNames =
    execWriterT $ execStackT $ makeTypeInfo (lift . lift . extraTypes) st >>= runReaderT typeGraphEdges >>= \ (g :: GraphEdges TGV) -> (mapM doType . map (view etype) . Map.keys . simpleEdges $ g)
    where
      st = map ConT typeNames

      doType (E (ConT name)) = qReify name >>= doInfo
      doType _ = return ()
      doInfo (TyConI dec@(NewtypeD _ typeName _ con _)) = doCons dec typeName [con]
      doInfo (TyConI dec@(DataD _ typeName _ cons _)) = doCons dec typeName cons
      doInfo _ = return ()
      doCons dec typeName cons = mapM_ (\ con -> mapM_ (foldField (doField typeName) dec con) (constructorFieldTypes con)) cons

      -- (mkName $ nameBase $ tName dec) dec lensNamer) >>= tell
      doField :: Name -> FieldType -> StackT (WriterT [Dec] m) ()
      doField typeName (Named (fieldName, _, fieldType)) =
          doFieldType typeName fieldName fieldType
      doField _ _ = return ()
      doFieldType typeName fieldName (ForallT _ _ typ) = doFieldType typeName fieldName typ
      doFieldType typeName fieldName fieldType@(ConT fieldTypeName) = qReify fieldTypeName >>= doFieldInfo typeName fieldName fieldType
      doFieldType typeName fieldName fieldType = makeLens typeName fieldName fieldType
      doFieldInfo typeName fieldName fieldType (TyConI _fieldTypeDec) = makeLens typeName fieldName fieldType
      doFieldInfo _ _ _ (PrimTyConI _ _ _) = return ()
      doFieldInfo _ _ _ info = error $ "makeLenses - doFieldType: " ++ show info

      makeLens typeName fieldName fieldType =
          do let lensName = mkName (lensNamer (nameBase fieldName))
             sig <- runQ $ sigD lensName (runQ [t|Lens' $(conT typeName) $(pure fieldType)|])
             val <- runQ $ valD (varP lensName) (normalB (runQ [|lens $(varE fieldName) (\ s x -> $(recUpdE [|s|] [ (,) <$> pure fieldName <*> [|x|] ]))|])) []
             return [sig, val] >>= tell

-- | Given a field name, return the name to use for the corresponding lens.
lensNamer :: String -> String
lensNamer (n : ame) = "lens" ++ [toUpper n] ++ ame
lensNamer "" = error "Saw the empty string as a field name"
