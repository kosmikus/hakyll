-- | A page is an important concept in Hakyll: it has a body (usually of the
-- type 'String') and number of metadata fields. This type is used to represent
-- pages on your website.
--
{-# LANGUAGE DeriveDataTypeable #-}
module Hakyll.Web.Page
    ( Page (..)
    , toMap
    ) where

import Control.Applicative ((<$>), (<*>))

import Data.Map (Map)
import qualified Data.Map as M
import Data.Binary (Binary, get, put)
import Data.Typeable (Typeable)

import Hakyll.Core.Writable

-- | Type used to represent pages
--
data Page a = Page
    { pageMetadata :: Map String String
    , pageBody     :: a
    } deriving (Show, Typeable)

instance Functor Page where
    fmap f (Page m b) = Page m (f b)

instance Binary a => Binary (Page a) where
    put (Page m b) = put m >> put b
    get = Page <$> get <*> get

instance Writable a => Writable (Page a) where
    write p (Page _ b) = write p b

-- | Convert a page to a map. The body will be placed in the @body@ key.
--
toMap :: Page String -> Map String String
toMap (Page m b) = M.insert "body" b m