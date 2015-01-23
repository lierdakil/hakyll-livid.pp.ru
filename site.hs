--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Monad
import           Data.Maybe
import           Data.Monoid     (mappend)
import           Hakyll
-- import           Data.List
import           System.FilePath
import           System.Locale


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match ("images/*" .||. "files/*") $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*.less" $ do
        route   $ setExtension "css"
        compile $ liftM (fmap compressCss) $ getResourceString >>=
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

    -- tag pages
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    let
        list !!? i | i < length list,
                     not.null $ list !! i  = Just $ list !! i
                   | otherwise = Nothing
        navigationField = functionField "navigation" navigationLink
        navigationLink args item = do
                  let filePath = head args
                      text = args !! 1
                      pattern = fromMaybe (fromList [identifier]) $
                                    liftM fromGlob $ args !!? 2
                      classes = fromMaybe "" $ args !!? 3
                      identifier = fromFilePath filePath
                      cls = "class=\"" ++(
                            if matches pattern (itemIdentifier item) then
                              "active"
                            else
                              ""
                            )++ classes ++ "\""
                  Just argUrl <- getRoute identifier
                  return $
                      "<li "++cls++"><a href=\"/"++argUrl++"\">"++
                      text ++"</a></li>"
        myDefaultContext =
                tagCloudField "tagCloud" 80 200 tags `mappend`
                navigationField                      `mappend`
                defaultContext
        timeLocale = defaultTimeLocale {
              wDays = [("Понедельник","Пн"),
                       ("Вторник",    "Вт"),
                       ("Среда",      "Ср"),
                       ("Четверг",    "Чт"),
                       ("Пятница",    "Пт"),
                       ("Суббота",    "Сб"),
                       ("Воскресенье","Вс")],
              months = [("Января",  "Янв"),
                        ("Февраля", "Фев"),
                        ("Марта",   "Мар"),
                        ("Апреля",  "Апр"),
                        ("Мая",     "Мая"),
                        ("Июня",    "Июн"),
                        ("Июля",    "Июл"),
                        ("Августа", "Авг"),
                        ("Сентября","Сен"),
                        ("Октября", "Окт"),
                        ("Ноября",  "Ноя"),
                        ("Декабря", "Дек")]
        }
        postCtx =
                dateFieldWith timeLocale "date" "%e %B, %Y"    `mappend`
                teaserField "teaser" "content"                 `mappend`
                field "disqusId" disqusId                      `mappend`
                tagsField "tags" tags                          `mappend`
                myDefaultContext
                where
                  disqusId = return.fst.splitExtension.toFilePath.itemIdentifier

    let postsPerPage = 10
    tagsRules tags $ \tag pattern -> do
      let pagePath page | page == 1 = fromCapture "tags/*.html" tag
                        | otherwise = fromFilePath $ "tags/"++tag++"/page/"++
                                                show (page::PageNumber)++".html"
      tagsPaginate <- buildPaginateWith
                            (liftM (paginateEvery postsPerPage).sortRecentFirst)
                            pattern pagePath
      let title = "Посты с тегом " ++ tag

      paginateRules tagsPaginate $ \pageNum pattern' -> do
          route idRoute
          compile $ do
            let posts = loadAllSnapshots pattern' "content" >>=
                        recentFirst
            let ctx = constField "title" title `mappend`
                      listField "posts" postCtx posts `mappend`
                      paginateContext tagsPaginate pageNum `mappend`
                      myDefaultContext
            makeItem ""
              >>= loadAndApplyTemplate "templates/archive.html" ctx
              >>= loadAndApplyTemplate "templates/default.html" ctx
              >>= relativizeUrls

    match "static/*" $ do
        route   $ setExtension "html"
        let ctx =
                  myDefaultContext
        let compiler ext | ext==".html" = getResourceBody
                         | otherwise    = pandocCompiler
        compile $ liftM (snd.splitExtension.toFilePath) getUnderlying
            >>= compiler
            >>= loadAndApplyTemplate "templates/static.html" ctx
            >>= loadAndApplyTemplate "templates/default.html" ctx
            >>= relativizeUrls

    match "posts/*" $ do
        route   $ setExtension "html"
        compile $
          pandocCompiler
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    -- archive pages
    let pagePath page | page==1   = fromFilePath   "index.html"
                      | otherwise = fromFilePath $ "archive/page/"++
                                                show (page::PageNumber)++".html"
    archivePaginate <- buildPaginateWith
                            (liftM (paginateEvery postsPerPage).sortRecentFirst)
                            "posts/*" pagePath
    paginateRules archivePaginate $ \pageNum pattern -> do
        route idRoute
        compile $ do
            let
                title | pageNum==1 = "Главная"
                      | otherwise  = "Архив"
                posts =
                  loadAllSnapshots pattern "content" >>=
                  recentFirst
                archiveCtx =
                  listField "posts" postCtx posts     `mappend`
                  constField "title" title            `mappend`
                  paginateContext archivePaginate pageNum `mappend`
                  myDefaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    let feedCtx = postCtx `mappend`
                  teaserField "description" "content" `mappend`
                  bodyField "description"
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
  { deployCommand = makeDeployCommand hostlist }
  where
    makeDeployCommand = foldl ((.(++"; ")).(++)) ""
                                        . map ("rsync -avz -e ssh ./_site/ "++)
    hostlist = [
                "solar:/var/www/livid.pp.ru/hakyll/",
                "vps.livid.pp.ru:/var/www/"
               ]
