--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import Control.Applicative
import Data.Monoid           (mappend)
import Hakyll
import System.FilePath

import Utils
import Navigation
import ArchiveByDate
--------------------------------------------------------------------------------

main :: IO ()
main = hakyllWith config $ do
    --images, css, js, etc
    basics

    let
      -- general paths
      tagsCap   = "tags/*.html"
      postsCap  = "posts/*"
      staticCap = "static/*"
      archiveDateCap = "archive/dates/*.html"
      archivePagePath 1 = "index.html"
      archivePagePath p = pagePath "*.html" "archive" p
      archiveDateIndexPath = "archive/index.html"
      -- page titles
      archiveTitle 1 = "Главная"
      archiveTitle _ = "Архив"
      tagsTitle tag _ = "Посты с тегом " ++ tag
      archiveDatesTitle date _ = "Посты за " ++ dateTagToStr date

    tags <- buildTags postsCap (fromCapture tagsCap)

    let
      myDefaultContext =
        tagCloudField "tagCloud" 80 200 tags `mappend`
        navigationField                      `mappend`
        defaultContext
      postCtx =
        dateFieldWith timeLocale "date" "%e %B, %Y"    `mappend`
        teaserField "teaser" "content"                 `mappend`
        field "disqusId" disqusId                      `mappend`
        tagsField "tags" tags                          `mappend`
        myDefaultContext
        where
          disqusId = return.fst.splitExtension.toFilePath.itemIdentifier
      postsField = listField "posts" postCtx . recentSnapshots
      sortPaginate' = sortPaginate 10
      doPaginateTemplate title template paginate =
        paginateRules paginate $ \pageNum pattern -> do
            route idRoute
            compile $ do
              let ctx = constField "title" (title pageNum)  `mappend`
                        postsField pattern                  `mappend`
                        paginateContext paginate pageNum    `mappend`
                        myDefaultContext
              makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" ctx
                >>= template ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls
      doPaginate title = doPaginateTemplate title (\_ item -> return item)

    match staticCap $ do
        route   $ setExtension "html"
        let ctx =
                  myDefaultContext
        let compiler ext | ext==".html" = getResourceBody
                         | otherwise    = pandocCompiler
        compile $ fmap (snd.splitExtension.toFilePath) getUnderlying
            >>= compiler
            >>= loadAndApplyTemplate "templates/static.html" ctx
            >>= loadAndApplyTemplate "templates/default.html" ctx
            >>= relativizeUrls

    match postsCap $ do
        route   $ setExtension "html"
        compile $
          pandocCompiler
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    tagsRules tags $ \tag pattern ->
      doPaginateTemplate (tagsTitle tag) (loadAndApplyTemplate "templates/static.html") =<<
        buildPaginateWith
          sortPaginate'
          pattern (pagePath tagsCap tag)

    doPaginate archiveTitle =<<
      buildPaginateWith
        sortPaginate'
        postsCap
        archivePagePath

    archiveDates <- buildArchiveDates
                            postsCap
                            (fromCapture archiveDateCap)

    tagsRules archiveDates $ \date pattern ->
      doPaginateTemplate (archiveDatesTitle date) (loadAndApplyTemplate "templates/static.html") =<<
        buildPaginateWith
          sortPaginate'
          pattern (pagePath archiveDateCap date)

    withTagDeps archiveDates $
      create [archiveDateIndexPath] $ do
        route idRoute
        compile $ do
          let ctx = constField "title" "Архив"    `mappend`
                    myDefaultContext
          renderArchiveDates archiveDates
            >>= makeItem
            >>= loadAndApplyTemplate "templates/default.html" ctx
            >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    let feedCtx = postCtx `mappend`
                  teaserField "description" "content" `mappend`
                  bodyField "description"
        posts = take 10 <$> recentSnapshots postsCap
    create ["rss.xml"] $ do
      route idRoute
      compile $ renderRss myFeedConfiguration feedCtx =<< posts
    create ["atom.xml"] $ do
      route idRoute
      compile $ renderAtom myFeedConfiguration feedCtx =<< posts


--------------------------------------------------------------------------------

basics :: Rules ()
basics = do
  match ("images/*" .||. "files/*") $ do
      route   idRoute
      compile copyFileCompiler

  match "css/*.less" $ do
      route   $ setExtension "css"
      compile $ fmap (fmap compressCss) $ getResourceString >>=
                withItemBody (unixFilter "lessc" ["-"])

  match "css/*.min.css" $ do
      route   idRoute
      compile copyFileCompiler

  match "css/*.css.map" $ do
      route   idRoute
      compile copyFileCompiler

  match "fonts/*" $ do
      route   idRoute
      compile copyFileCompiler

  match "js/*" $ do
      route   idRoute
      compile copyFileCompiler

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
  { deployCommand = makeDeployCommand hostlist }
  where
    makeDeployCommand = foldl ((.(++"; ")).(++)) ""
                                        . ("git push":)
                                        . map ("rsync -avcz -e ssh ./_site/ "++)
    hostlist = [
                  "solar:/var/www/livid.pp.ru/hakyll/"
                -- , "vps:/var/www/"
               ]
