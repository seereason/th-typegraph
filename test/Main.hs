{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

-- import Data.Aeson
-- import Language.Haskell.TH.TypeGraph.Aeson (deriveJSON)
import Language.Haskell.TH.Lift (lift)
import Language.Haskell.TH.TypeGraph.Constraints (monomorphize)
import Language.Haskell.TH.TypeGraph.Serialize (deriveSerialize)
import Language.Haskell.TH.TypeGraph.TypeTraversal (pprint1)
import Language.Haskell.TH.TypeGraph.WebRoutesTH (derivePathInfo)
import Prelude hiding (concat)
import "th-typegraph" Data.Aeson.TH
--import Data.Generics
--import Data.Monoid (mconcat)
import Test.HUnit

import Types

default (String)

-- The deriveJSON function provided by aeson puts constraints ToJSON
-- t, ToJSON s, ToJSON a on the instances.  The ToJSON t constraint is
-- unnecessary because it doesn't actually appear in the value, and we
-- need constraints ToJSON (KeyType t) but they are omitted.

-- $(deriveJSON defaultOptions ''Hop)
-- $(deriveJSON defaultOptions ''TraversalPath)



tests :: Test
tests = do
  TestList
    [ TestCase
        (assertEqual "deriveSerialize Hop"
           ("instance Serialize key => Serialize (Hop key) where put (NamedField a1 a2 a3 a4 a5 a6 a7) = ((((((putWord8 0 >> put a1) >> put a2) >> put a3) >> put a4) >> put a5) >> put a6) >> put a7 put (AnonField a1 a2 a3 a4 a5 a6) = (((((putWord8 1 >> put a1) >> put a2) >> put a3) >> put a4) >> put a5) >> put a6 put (TupleHop a1) = putWord8 2 >> put a1 put (IndexHop a1) = putWord8 3 >> put a1 put (ViewHop) = putWord8 4 put (IxViewHop a1) = putWord8 5 >> put a1 get = getWord8 >>= (\\i -> case i of 0 -> ((((((pure NamedField <*> get) <*> get) <*> get) <*> get) <*> get) <*> get) <*> get 1 -> (((((pure AnonField <*> get) <*> get) <*> get) <*> get) <*> get) <*> get 2 -> pure TupleHop <*> get 3 -> pure IndexHop <*> get 4 -> pure ViewHop 5 -> pure IxViewHop <*> get n -> error $ (\"deriveSerialize - unexpected tag: \" ++ show n))" :: String)
           $(deriveSerialize [t|Hop|] >>= lift . pprint1))
    , TestCase (assertEqual "deriveSerialize TraversalPath"
                  ("instance (Serialize (KeyType t), Serialize (ProxyType t)) => Serialize (TraversalPath t s a) where put (TraversalPath a1 a2 a3) = (put a1 >> put a2) >> put a3 get = ((pure TraversalPath <*> get) <*> get) <*> get" :: String)
                  $(deriveSerialize [t|TraversalPath|] >>= lift . pprint1))
    , TestCase
        (assertEqual "deriveSerialize (ValueType TestPaths)"
           ("instance Serialize (ValueType TestPaths) where put (V_Eitherz20UURIz20UInteger a1) = putWord8 0 >> put a1 put (V_Int a1) = putWord8 1 >> put a1 put (V_Integer a1) = putWord8 2 >> put a1 put (V_Loc a1) = putWord8 3 >> put a1 put (V_Maybez20UURIAuth a1) = putWord8 4 >> put a1 put (V_Maybez20UZLEitherz20UURIz20UIntegerZR a1) = putWord8 5 >> put a1 put (V_Name a1) = putWord8 6 >> put a1 put (V_TyLit a1) = putWord8 7 >> put a1 put (V_TyVarBndr a1) = putWord8 8 >> put a1 put (V_Type a1) = putWord8 9 >> put a1 put (V_URI a1) = putWord8 10 >> put a1 put (V_URIAuth a1) = putWord8 11 >> put a1 put (V_ZLIntz2cUz20UIntZR a1) = putWord8 12 >> put a1 put (V_ZLIntz2cUz20UTyVarBndrZR a1) = putWord8 13 >> put a1 put (V_ZLIntz2cUz20UTypeZR a1) = putWord8 14 >> put a1 put (V_ZLIntz2cUz20UZMCharZNZR a1) = putWord8 15 >> put a1 put (V_ZMCharZN a1) = putWord8 16 >> put a1 put (V_ZMIntZN a1) = putWord8 17 >> put a1 put (V_ZMTyVarBndrZN a1) = putWord8 18 >> put a1 put (V_ZMTypeZN a1) = putWord8 19 >> put a1 put (V_ZMZMCharZNZN a1) = putWord8 20 >> put a1 get = getWord8 >>= (\\i -> case i of 0 -> pure V_Eitherz20UURIz20UInteger <*> get 1 -> pure V_Int <*> get 2 -> pure V_Integer <*> get 3 -> pure V_Loc <*> get 4 -> pure V_Maybez20UURIAuth <*> get 5 -> pure V_Maybez20UZLEitherz20UURIz20UIntegerZR <*> get 6 -> pure V_Name <*> get 7 -> pure V_TyLit <*> get 8 -> pure V_TyVarBndr <*> get 9 -> pure V_Type <*> get 10 -> pure V_URI <*> get 11 -> pure V_URIAuth <*> get 12 -> pure V_ZLIntz2cUz20UIntZR <*> get 13 -> pure V_ZLIntz2cUz20UTyVarBndrZR <*> get 14 -> pure V_ZLIntz2cUz20UTypeZR <*> get 15 -> pure V_ZLIntz2cUz20UZMCharZNZR <*> get 16 -> pure V_ZMCharZN <*> get 17 -> pure V_ZMIntZN <*> get 18 -> pure V_ZMTyVarBndrZN <*> get 19 -> pure V_ZMTypeZN <*> get 20 -> pure V_ZMZMCharZNZN <*> get n -> error $ (\"deriveSerialize - unexpected tag: \" ++ show n))" :: String)
           $(deriveSerialize [t|ValueType TestPaths|] >>= lift . pprint1))
    , TestCase
        (assertEqual "derivePathInfo Hop"
           ("instance PathInfo key => PathInfo (Hop key) where toPathSegments inp = case inp of NamedField arg arg arg arg arg arg arg -> (++) [pack \"named-field\"] ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) (toPathSegments arg))))))) AnonField arg arg arg arg arg arg -> (++) [pack \"anon-field\"] ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) ((++) (toPathSegments arg) (toPathSegments arg)))))) TupleHop arg -> (++) [pack \"tuple-hop\"] (toPathSegments arg) IndexHop arg -> (++) [pack \"index-hop\"] (toPathSegments arg) ViewHop -> [pack \"view-hop\"] IxViewHop arg -> (++) [pack \"ix-view-hop\"] (toPathSegments arg) fromPathSegments = (<|>) ((<|>) ((<|>) ((<|>) ((<|>) (ap (ap (ap (ap (ap (ap (ap (segment (pack \"named-field\") >> return NamedField) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments) (ap (ap (ap (ap (ap (ap (segment (pack \"anon-field\") >> return AnonField) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments) fromPathSegments)) (ap (segment (pack \"tuple-hop\") >> return TupleHop) fromPathSegments)) (ap (segment (pack \"index-hop\") >> return IndexHop) fromPathSegments)) (segment (pack \"view-hop\") >> return ViewHop)) (ap (segment (pack \"ix-view-hop\") >> return IxViewHop) fromPathSegments)" :: String)
           $(derivePathInfo [t|Hop|] >>= lift . pprint1))
    , TestCase
        (assertEqual "derivePathInfo (ProxyType TestPaths)"
           ("instance PathInfo (ProxyType TestPaths) where toPathSegments inp = case inp of P_Eitherz20UURIz20UInteger -> [pack \"p_-eitherz20-u-u-r-iz20-u-integer\"] P_Int -> [pack \"p_-int\"] P_Integer -> [pack \"p_-integer\"] P_Loc -> [pack \"p_-loc\"] P_Maybez20UURIAuth -> [pack \"p_-maybez20-u-u-r-i-auth\"] P_Maybez20UZLEitherz20UURIz20UIntegerZR -> [pack \"p_-maybez20-u-z-l-eitherz20-u-u-r-iz20-u-integer-z-r\"] P_Name -> [pack \"p_-name\"] P_TyLit -> [pack \"p_-ty-lit\"] P_TyVarBndr -> [pack \"p_-ty-var-bndr\"] P_Type -> [pack \"p_-type\"] P_URI -> [pack \"p_-u-r-i\"] P_URIAuth -> [pack \"p_-u-r-i-auth\"] P_ZLIntz2cUz20UIntZR -> [pack \"p_-z-l-intz2c-uz20-u-int-z-r\"] P_ZLIntz2cUz20UTyVarBndrZR -> [pack \"p_-z-l-intz2c-uz20-u-ty-var-bndr-z-r\"] P_ZLIntz2cUz20UTypeZR -> [pack \"p_-z-l-intz2c-uz20-u-type-z-r\"] P_ZLIntz2cUz20UZMCharZNZR -> [pack \"p_-z-l-intz2c-uz20-u-z-m-char-z-n-z-r\"] P_ZMCharZN -> [pack \"p_-z-m-char-z-n\"] P_ZMIntZN -> [pack \"p_-z-m-int-z-n\"] P_ZMTyVarBndrZN -> [pack \"p_-z-m-ty-var-bndr-z-n\"] P_ZMTypeZN -> [pack \"p_-z-m-type-z-n\"] P_ZMZMCharZNZN -> [pack \"p_-z-m-z-m-char-z-n-z-n\"] fromPathSegments = (<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) ((<|>) (segment (pack \"p_-eitherz20-u-u-r-iz20-u-integer\") >> return P_Eitherz20UURIz20UInteger) (segment (pack \"p_-int\") >> return P_Int)) (segment (pack \"p_-integer\") >> return P_Integer)) (segment (pack \"p_-loc\") >> return P_Loc)) (segment (pack \"p_-maybez20-u-u-r-i-auth\") >> return P_Maybez20UURIAuth)) (segment (pack \"p_-maybez20-u-z-l-eitherz20-u-u-r-iz20-u-integer-z-r\") >> return P_Maybez20UZLEitherz20UURIz20UIntegerZR)) (segment (pack \"p_-name\") >> return P_Name)) (segment (pack \"p_-ty-lit\") >> return P_TyLit)) (segment (pack \"p_-ty-var-bndr\") >> return P_TyVarBndr)) (segment (pack \"p_-type\") >> return P_Type)) (segment (pack \"p_-u-r-i\") >> return P_URI)) (segment (pack \"p_-u-r-i-auth\") >> return P_URIAuth)) (segment (pack \"p_-z-l-intz2c-uz20-u-int-z-r\") >> return P_ZLIntz2cUz20UIntZR)) (segment (pack \"p_-z-l-intz2c-uz20-u-ty-var-bndr-z-r\") >> return P_ZLIntz2cUz20UTyVarBndrZR)) (segment (pack \"p_-z-l-intz2c-uz20-u-type-z-r\") >> return P_ZLIntz2cUz20UTypeZR)) (segment (pack \"p_-z-l-intz2c-uz20-u-z-m-char-z-n-z-r\") >> return P_ZLIntz2cUz20UZMCharZNZR)) (segment (pack \"p_-z-m-char-z-n\") >> return P_ZMCharZN)) (segment (pack \"p_-z-m-int-z-n\") >> return P_ZMIntZN)) (segment (pack \"p_-z-m-ty-var-bndr-z-n\") >> return P_ZMTyVarBndrZN)) (segment (pack \"p_-z-m-type-z-n\") >> return P_ZMTypeZN)) (segment (pack \"p_-z-m-z-m-char-z-n-z-n\") >> return P_ZMZMCharZNZN)" :: String)
           $(derivePathInfo [t|ProxyType TestPaths|] >>= lift . pprint1))
    , TestCase
        (assertEqual "deriveJSON TraversalPath"
           (concat ["instance (ToJSON (KeyType (t :: *)), ToJSON (ProxyType (t :: *))) => ToJSON (TraversalPath t s a) where ",
                      "toJSON = \\value -> case value of TraversalPath arg1 arg2 arg3 -> Array (create (do {mv <- unsafeNew 3; unsafeWrite mv 0 (toJSON arg1); unsafeWrite mv 1 (toJSON arg2); unsafeWrite mv 2 (toJSON arg3); return mv})) ",
                      "toEncoding = \\value -> case value of TraversalPath arg1 arg2 arg3 -> Encoding (char7 '[' <> ((builder arg1 <> (char7 ',' <> (builder arg2 <> (char7 ',' <> builder arg3)))) <> char7 ']')) ",
                    "instance (FromJSON (KeyType (t :: *)), FromJSON (ProxyType (t :: *))) => FromJSON (TraversalPath t s a) where ",
                      "parseJSON = \\value -> case value of ",
                                                "Array arr -> if length arr == 3 then ((TraversalPath <$> parseJSON (arr `unsafeIndex` 0)) <*> parseJSON (arr `unsafeIndex` 1)) <*> parseJSON (arr `unsafeIndex` 2) else parseTypeMismatch' \"TraversalPath\" \"Types.TraversalPath\" \"Array of length 3\" (\"Array of length \" ++ (show . length) arr) ",
                                                "other -> parseTypeMismatch' \"TraversalPath\" \"Types.TraversalPath\" \"Array\" (valueConName other)"] :: String)
           $(deriveJSON' defaultOptions [t|TraversalPath|] >>= lift . pprint1))
    , TestCase
        (assertEqual "deriveJSON' defaultOptions [t|ValueType TestPaths|]"
           ("instance ToJSON (ValueType TestPaths) where toJSON = \\value -> case value of V_Eitherz20UURIz20UInteger arg1 -> object [pack \"tag\" .= String (pack \"V_Eitherz20UURIz20UInteger\"), pack \"contents\" .= toJSON arg1] V_Int arg1 -> object [pack \"tag\" .= String (pack \"V_Int\"), pack \"contents\" .= toJSON arg1] V_Integer arg1 -> object [pack \"tag\" .= String (pack \"V_Integer\"), pack \"contents\" .= toJSON arg1] V_Loc arg1 -> object [pack \"tag\" .= String (pack \"V_Loc\"), pack \"contents\" .= toJSON arg1] V_Maybez20UURIAuth arg1 -> object [pack \"tag\" .= String (pack \"V_Maybez20UURIAuth\"), pack \"contents\" .= toJSON arg1] V_Maybez20UZLEitherz20UURIz20UIntegerZR arg1 -> object [pack \"tag\" .= String (pack \"V_Maybez20UZLEitherz20UURIz20UIntegerZR\"), pack \"contents\" .= toJSON arg1] V_Name arg1 -> object [pack \"tag\" .= String (pack \"V_Name\"), pack \"contents\" .= toJSON arg1] V_TyLit arg1 -> object [pack \"tag\" .= String (pack \"V_TyLit\"), pack \"contents\" .= toJSON arg1] V_TyVarBndr arg1 -> object [pack \"tag\" .= String (pack \"V_TyVarBndr\"), pack \"contents\" .= toJSON arg1] V_Type arg1 -> object [pack \"tag\" .= String (pack \"V_Type\"), pack \"contents\" .= toJSON arg1] V_URI arg1 -> object [pack \"tag\" .= String (pack \"V_URI\"), pack \"contents\" .= toJSON arg1] V_URIAuth arg1 -> object [pack \"tag\" .= String (pack \"V_URIAuth\"), pack \"contents\" .= toJSON arg1] V_ZLIntz2cUz20UIntZR arg1 -> object [pack \"tag\" .= String (pack \"V_ZLIntz2cUz20UIntZR\"), pack \"contents\" .= toJSON arg1] V_ZLIntz2cUz20UTyVarBndrZR arg1 -> object [pack \"tag\" .= String (pack \"V_ZLIntz2cUz20UTyVarBndrZR\"), pack \"contents\" .= toJSON arg1] V_ZLIntz2cUz20UTypeZR arg1 -> object [pack \"tag\" .= String (pack \"V_ZLIntz2cUz20UTypeZR\"), pack \"contents\" .= toJSON arg1] V_ZLIntz2cUz20UZMCharZNZR arg1 -> object [pack \"tag\" .= String (pack \"V_ZLIntz2cUz20UZMCharZNZR\"), pack \"contents\" .= toJSON arg1] V_ZMCharZN arg1 -> object [pack \"tag\" .= String (pack \"V_ZMCharZN\"), pack \"contents\" .= toJSON arg1] V_ZMIntZN arg1 -> object [pack \"tag\" .= String (pack \"V_ZMIntZN\"), pack \"contents\" .= toJSON arg1] V_ZMTyVarBndrZN arg1 -> object [pack \"tag\" .= String (pack \"V_ZMTyVarBndrZN\"), pack \"contents\" .= toJSON arg1] V_ZMTypeZN arg1 -> object [pack \"tag\" .= String (pack \"V_ZMTypeZN\"), pack \"contents\" .= toJSON arg1] V_ZMZMCharZNZN arg1 -> object [pack \"tag\" .= String (pack \"V_ZMZMCharZNZN\"), pack \"contents\" .= toJSON arg1] toEncoding = \\value -> case value of V_Eitherz20UURIz20UInteger arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Eitherz20UURIz20UInteger\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Int arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Int\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Integer arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Integer\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Loc arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Loc\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Maybez20UURIAuth arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Maybez20UURIAuth\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Maybez20UZLEitherz20UURIz20UIntegerZR arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Maybez20UZLEitherz20UURIz20UIntegerZR\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Name arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Name\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_TyLit arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_TyLit\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_TyVarBndr arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_TyVarBndr\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_Type arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_Type\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_URI arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_URI\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_URIAuth arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_URIAuth\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZLIntz2cUz20UIntZR arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZLIntz2cUz20UIntZR\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZLIntz2cUz20UTyVarBndrZR arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZLIntz2cUz20UTyVarBndrZR\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZLIntz2cUz20UTypeZR arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZLIntz2cUz20UTypeZR\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZLIntz2cUz20UZMCharZNZR arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZLIntz2cUz20UZMCharZNZR\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZMCharZN arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZMCharZN\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZMIntZN arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZMIntZN\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZMTyVarBndrZN arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZMTyVarBndrZN\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZMTypeZN arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZMTypeZN\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) V_ZMZMCharZNZN arg1 -> Encoding (char7 '{' <> (((text (pack \"tag\") <> (char7 ':' <> text (pack \"V_ZMZMCharZNZN\"))) <> (char7 ',' <> (text (pack \"contents\") <> (char7 ':' <> fromEncoding (toEncoding arg1))))) <> char7 '}')) instance FromJSON (ValueType TestPaths) where parseJSON = \\value -> case value of Object obj -> do {conKey <- obj .: pack \"tag\"; case conKey of _ | conKey == pack \"V_Eitherz20UURIz20UInteger\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Eitherz20UURIz20UInteger <$> parseJSON arg} | conKey == pack \"V_Int\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Int <$> parseJSON arg} | conKey == pack \"V_Integer\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Integer <$> parseJSON arg} | conKey == pack \"V_Loc\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Loc <$> parseJSON arg} | conKey == pack \"V_Maybez20UURIAuth\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Maybez20UURIAuth <$> parseJSON arg} | conKey == pack \"V_Maybez20UZLEitherz20UURIz20UIntegerZR\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Maybez20UZLEitherz20UURIz20UIntegerZR <$> parseJSON arg} | conKey == pack \"V_Name\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Name <$> parseJSON arg} | conKey == pack \"V_TyLit\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_TyLit <$> parseJSON arg} | conKey == pack \"V_TyVarBndr\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_TyVarBndr <$> parseJSON arg} | conKey == pack \"V_Type\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_Type <$> parseJSON arg} | conKey == pack \"V_URI\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_URI <$> parseJSON arg} | conKey == pack \"V_URIAuth\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_URIAuth <$> parseJSON arg} | conKey == pack \"V_ZLIntz2cUz20UIntZR\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZLIntz2cUz20UIntZR <$> parseJSON arg} | conKey == pack \"V_ZLIntz2cUz20UTyVarBndrZR\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZLIntz2cUz20UTyVarBndrZR <$> parseJSON arg} | conKey == pack \"V_ZLIntz2cUz20UTypeZR\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZLIntz2cUz20UTypeZR <$> parseJSON arg} | conKey == pack \"V_ZLIntz2cUz20UZMCharZNZR\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZLIntz2cUz20UZMCharZNZR <$> parseJSON arg} | conKey == pack \"V_ZMCharZN\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZMCharZN <$> parseJSON arg} | conKey == pack \"V_ZMIntZN\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZMIntZN <$> parseJSON arg} | conKey == pack \"V_ZMTyVarBndrZN\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZMTyVarBndrZN <$> parseJSON arg} | conKey == pack \"V_ZMTypeZN\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZMTypeZN <$> parseJSON arg} | conKey == pack \"V_ZMZMCharZNZN\" -> do {val <- obj .: pack \"contents\"; case val of arg -> V_ZMZMCharZNZN <$> parseJSON arg} | otherwise -> conNotFoundFailTaggedObject \"Types.ValueType\" [\"V_Eitherz20UURIz20UInteger\", \"V_Int\", \"V_Integer\", \"V_Loc\", \"V_Maybez20UURIAuth\", \"V_Maybez20UZLEitherz20UURIz20UIntegerZR\", \"V_Name\", \"V_TyLit\", \"V_TyVarBndr\", \"V_Type\", \"V_URI\", \"V_URIAuth\", \"V_ZLIntz2cUz20UIntZR\", \"V_ZLIntz2cUz20UTyVarBndrZR\", \"V_ZLIntz2cUz20UTypeZR\", \"V_ZLIntz2cUz20UZMCharZNZR\", \"V_ZMCharZN\", \"V_ZMIntZN\", \"V_ZMTyVarBndrZN\", \"V_ZMTypeZN\", \"V_ZMZMCharZNZN\"] (unpack conKey)} other -> noObjectFail \"Types.ValueType\" (valueConName other)" :: String)
           $(deriveJSON' defaultOptions [t|ValueType TestPaths|] >>= lift . pprint1))
    , TestCase
        (assertEqual "deriveJSON' defaultOptions [t|OldType Schema1 Author|]"
           ("instance ToJSON (OldType Schema1 Author) where toJSON = \\value -> case value of Author_Schema1 arg1 arg2 arg3 arg4 -> Array (create (do {mv <- unsafeNew 4; unsafeWrite mv 0 (toJSON arg1); unsafeWrite mv 1 (toJSON arg2); unsafeWrite mv 2 (toJSON arg3); unsafeWrite mv 3 (toJSON arg4); return mv})) toEncoding = \\value -> case value of Author_Schema1 arg1 arg2 arg3 arg4 -> Encoding (char7 '[' <> ((builder arg1 <> (char7 ',' <> (builder arg2 <> (char7 ',' <> (builder arg3 <> (char7 ',' <> builder arg4)))))) <> char7 ']')) instance FromJSON (OldType Schema1 Author) where parseJSON = \\value -> case value of Array arr -> if length arr == 4 then (((Author_Schema1 <$> parseJSON (arr `unsafeIndex` 0)) <*> parseJSON (arr `unsafeIndex` 1)) <*> parseJSON (arr `unsafeIndex` 2)) <*> parseJSON (arr `unsafeIndex` 3) else parseTypeMismatch' \"Author_Schema1\" \"Types.OldType\" \"Array of length 4\" (\"Array of length \" ++ (show . length) arr) other -> parseTypeMismatch' \"Author_Schema1\" \"Types.OldType\" \"Array\" (valueConName other)" :: String)
           $(deriveJSON' defaultOptions [t|OldType Schema1 Author|] >>= lift . pprint1))
    , TestCase
        (assertEqual "derivePathInfo TraversalPath"
           ("instance (PathInfo (KeyType t), PathInfo (ProxyType t)) => PathInfo (TraversalPath t s a) where toPathSegments inp = case inp of TraversalPath arg arg arg -> (++) [pack \"traversal-path\"] ((++) (toPathSegments arg) ((++) (toPathSegments arg) (toPathSegments arg))) fromPathSegments = ap (ap (ap (segment (pack \"traversal-path\") >> return TraversalPath) fromPathSegments) fromPathSegments) fromPathSegments" :: String)
           $(derivePathInfo [t|TraversalPath|] >>= lift . pprint1))
    , TestCase (assertEqual "monomorphize Hop" ("Hop key" :: String) $(monomorphize [t|Hop|] >>= lift . pprint1))
    , TestCase (assertEqual "monomorphize TraversalPath" ("TraversalPath t s a" :: String) $(monomorphize [t|TraversalPath|] >>= lift . pprint1))
    , TestCase (assertEqual "monomorphize TraversalPath" ("TraversalPath TestPaths s a" :: String) $(monomorphize [t|TraversalPath TestPaths|] >>= lift . pprint1))
    ]

-- | Without a specialized concat the text values come out as @pack ['a', 'b', 'c']@
concat :: [String] -> String
concat = mconcat

main :: IO ()
main = do
  counts <- runTestTT tests
  case counts of
    Counts {errors = 0, failures = 0} -> pure ()
    _ -> error (showCounts counts)
