--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Control.Monad
import           Data.Maybe
import           Network.HTTP
import           Hakyll
-- import           Data.List
import           System.FilePath


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match ("images/*" .||. "files/*") $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- tag pages
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    let tagCloud = tagCloudField "tagCloud" 80 200 tags
    let
        list !!? i | i < length list = Just $ list !! i
                   | otherwise = Nothing
        navigationField = functionField "navigation" navigationLink
        navigationLink args item = do
                  let filePath = head args
                      text = args !! 1
                      pattern = fromMaybe (fromList [identifier]) $
                                    liftM fromGlob $ args !!? 2
                      identifier = fromFilePath filePath
                      cls =
                            if matches pattern (itemIdentifier item) then
                              "class=\"active\""
                            else
                              ""
                  Just argUrl <- getRoute identifier
                  return $
                      "<a href=\"/"++argUrl++"\""++
                      cls ++
                      ">"++ text ++"</a>"

    let myDefaultContext =
                tagCloud        `mappend`
                navigationField `mappend`
                defaultContext
        postCtx =
                dateField "date" "%B %e, %Y"    `mappend`
                teaserField "teaser" "content"  `mappend`
                field "disqusId" disqusId       `mappend`
                myDefaultContext
                where
                  disqusId = return.fst.splitExtension.toFilePath.itemIdentifier

    tagsRules tags $ \tag pattern -> do
      let title = "Посты с тегом " ++ tag

      route idRoute
      compile $ do
        let posts = loadAllSnapshots pattern "content" >>=
                    recentFirst
        let ctx = constField "title" title `mappend`
                  listField "posts" postCtx posts `mappend`
                  myDefaultContext
        makeItem ""
          >>= loadAndApplyTemplate "templates/tags.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

    match "static/*" $ do
        route   $ setExtension "html"
        let ctx =
                  myDefaultContext
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" ctx
            >>= relativizeUrls

    match "posts/*" $ do
        route   $ setExtension "html"
        compile $ do
          identifier <- getUnderlying
          route' <- getRoute identifier
          let route1 = fromMaybe "undefined" route'
          let postCtx' = constField "url" (replaceAll "%2F" (const "/") $ urlEncode route1) `mappend`
                          postCtx
          pandocCompiler
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    postCtx'
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    -- archive pages
    let postsPerPage = 10
        pagePath page = fromFilePath $ "archive/page/"++show (page::PageNumber)++".html"
    archivePaginate <- buildPaginateWith (return.paginateEvery postsPerPage.drop postsPerPage.reverse) "posts/*" pagePath
    paginateRules archivePaginate $ \pageNum pattern -> do
        route idRoute
        compile $ do
            let posts =
                  loadAllSnapshots pattern "content" >>=
                  recentFirst
                archiveCtx =
                  listField "posts" postCtx posts     `mappend`
                  constField "title" "Архив"          `mappend`
                  paginateContext archivePaginate pageNum `mappend`
                  constField "previousPageUrl" "/"         `mappend`
                  myDefaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            let posts =
                  liftM (take postsPerPage) $
                  loadAllSnapshots "posts/*" "content" >>=
                  recentFirst
                indexCtx =
                  listField "posts" postCtx posts    `mappend`
                  constField "title" "Главная"       `mappend`
                  myDefaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    let feedCtx = postCtx `mappend` bodyField "description"
        posts = fmap (take 10) . recentFirst =<<
                  loadAllSnapshots "posts/*" "content"
    create ["rss.xml"] $ do
      route idRoute
      compile $ renderRss myFeedConfiguration feedCtx =<< posts
    create ["atom.xml"] $ do
      route idRoute
      compile $ renderAtom myFeedConfiguration feedCtx =<< posts


--------------------------------------------------------------------------------

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
  { feedTitle       = "Красноглазый блог"
  , feedDescription = "Записки о GNU/Linux и СПО"
  , feedAuthorName  = "Nikolay \"Livid\" Yakimov"
  , feedAuthorEmail = "root@livid.pp.ru"
  , feedRoot        = "http://livid.pp.ru"
  }

config :: Configuration
config = defaultConfiguration
  {   deployCommand = "rsync -avz -e ssh ./_site/ solar:/var/www/livid.pp.ru/hakyll"}
