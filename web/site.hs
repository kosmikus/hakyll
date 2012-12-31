--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Applicative ((<$>))
import           Control.Arrow       (second)
import           Control.Monad       (forM_)
import           Data.List           (isPrefixOf)
import           Data.Monoid         (mappend)
import           Hakyll
import           System.FilePath     (dropTrailingPathSeparator, splitPath)
import           Text.Pandoc


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- Static directories
    forM_ ["images/*", "examples/*"] $ \f -> match f $ do
        route   idRoute
        compile copyFileCompiler

    -- Haddock stuff
    match "reference/**.html" $ do
        route   idRoute
        compile $ fmap (withUrls hackage) <$> getResourceString

    -- Haddock stuff
    match ("reference/**" `mappend` complement "**.html") $ do
        route   idRoute
        compile copyFileCompiler

    -- Pages
    match "*.markdown" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    -- Tutorials
    match "tutorials/*" $ do
        route   $ setExtension "html"
        compile $ pandocCompilerWith defaultHakyllParserState withToc
            >>= loadAndApplyTemplate "templates/tutorial.html" defaultContext
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    -- Tutorial list
    match "tutorials.html" $ do
        route idRoute
        compile $ do
            tutorials <- loadAll "tutorials/*"
            itemTpl   <- loadBody "templates/tutorial-item.html"
            list      <- applyTemplateList itemTpl defaultContext $
                chronological tutorials

            let tutorialsCtx =
                    constField "title" "Tutorials" `mappend`
                    constField "tutorials" list    `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/tutorials.html" tutorialsCtx
                >>= loadAndApplyTemplate "templates/default.html" tutorialsCtx
                >>= relativizeUrls

    -- Templates
    match "templates/*" $ compile templateCompiler
  where
    withToc = defaultHakyllWriterOptions
        { writerTableOfContents = True
        , writerTemplate = "$toc$\n$body$"
        , writerStandalone = True
        }


--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
    { verbosity     = Debug
    , deployCommand = "rsync --checksum -ave 'ssh -p 2222' \
                      \_site/* jaspervdj@jaspervdj.be:jaspervdj.be/tmp/hakyll4"
    }


--------------------------------------------------------------------------------
-- | Turns
--
-- > /usr/share/doc/ghc/html/libraries/base-4.6.0.0/Data-String.html
--
-- into
--
-- > http://hackage.haskell.org/packages/archive/base/4.6.0.0/doc/html/Data-String.html
hackage :: String -> String
hackage url
    | "/usr" `isPrefixOf` url =
        "http://hackage.haskell.org/packages/archive/" ++
        packageName ++ "/" ++ version' ++ "/doc/html/" ++ baseName
    | otherwise               = url
  where
    (packageName, version')  = second (drop 1) $ break (== '-') package
    (baseName : package : _) = map dropTrailingPathSeparator $
        reverse $ splitPath url