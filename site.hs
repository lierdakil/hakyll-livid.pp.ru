--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Monad
import           Data.Maybe
import           Data.Monoid      (mappend)
import           Hakyll
import           System.FilePath
import           System.Locale
import           Data.List
import           Data.Function    (on)
import           Data.Time.Format (formatTime)
import           Text.Blaze.Html                 (toHtml, toValue, (!))
import           Text.Blaze.Html.Renderer.String (renderHtml)
import qualified Text.Blaze.Html5                as H
import qualified Text.Blaze.Html5.Attributes     as A


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
                                    liftM fromRegex $ args !!? 2
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
        recentSnapshots pattern = loadAllSnapshots pattern "content" >>= recentFirst
        postsField = listField "posts" postCtx . recentSnapshots

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
            let ctx = constField "title" title `mappend`
                      postsField pattern'      `mappend`
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
                archiveCtx =
                  postsField pattern                  `mappend`
                  constField "title" title            `mappend`
                  paginateContext archivePaginate pageNum `mappend`
                  myDefaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    let
        sortByDate x = do
                          time <- getItemUTC defaultTimeLocale x
                          return [formatTime defaultTimeLocale "%Y-%m" time]
        archivePattern = "archive/dates/*.html"
        archiveId = fromCapture archivePattern

    archiveDates <- buildTagsWith
                            sortByDate
                            "posts/*"
                            archiveId

    tagsRules archiveDates $ \tag pattern -> do
      let pagePath' page | page == 1 = archiveId tag
                         | otherwise = archiveId $ tag++"/page/"++show page
      tagsPaginate <- buildPaginateWith
                            (liftM (paginateEvery postsPerPage).sortRecentFirst)
                            pattern pagePath'
      let title = "Посты за " ++ tag

      paginateRules tagsPaginate $ \pageNum pattern' -> do
          route idRoute
          compile $ do
            let ctx = constField "title" title `mappend`
                      postsField pattern' `mappend`
                      paginateContext tagsPaginate pageNum `mappend`
                      myDefaultContext
            makeItem ""
              >>= loadAndApplyTemplate "templates/archive.html" ctx
              >>= loadAndApplyTemplate "templates/default.html" ctx
              >>= relativizeUrls

    let tagDeps t = map (IdentifierDependency . tagsMakeId t . fst) $ tagsMap t
    rulesExtraDependencies (tagDeps archiveDates) $
      create ["archive/index.html"] $ do
        route idRoute
        compile $ do
          let ctx = constField "title" "Архив"    `mappend`
                    myDefaultContext
              link tag url count =
                  (take 4 tag, (subtract 1 $ read $ drop 5 tag, url , show count))
              list ls =
                let
                    getYears = map head $ group $ map fst ls
                    getMonths = map (map snd) $ groupBy ((==) `on` fst) ls
                    years = reverse $ zip getYears getMonths
                    showYear (year, months') = renderHtml (H.h1 $ toHtml year) ++ renderHtml (H.ul $ showMonths months')
                    showMonths = foldl (\acc x -> acc >> showMonth x) ""
                    showMonth (month,url,count) = H.li $ H.a ! A.href (toValue url) $ toHtml $ monthNames !! month ++ " (" ++ count ++ ")"
                    monthNames :: [String]
                    monthNames = ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"]
                in
                foldl (\acc x -> acc ++ showYear x) "" years
              renderTags' makeHtml concatHtml tags1 = do
                  -- In tags' we create a list: [((tag, route), count)]
                  tags' <- forM (tagsMap tags1) $ \(tag, ids) -> do
                      route' <- getRoute $ tagsMakeId tags1 tag
                      return ((tag, route'), length ids)

                  -- TODO: We actually need to tell a dependency here!

                  let -- Absolute frequencies of the pages
                      -- Create a link for one item
                      makeHtml' ((tag, url), count) =
                          makeHtml tag (toUrl $ fromMaybe "/" url) count

                  -- Render and return the HTML
                  return $ concatHtml $ map makeHtml' tags'
          renderTags' link list archiveDates
            >>= makeItem
            >>= loadAndApplyTemplate "templates/default.html" ctx
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
                                        . ("git push":)
                                        . map ("rsync -avcz -e ssh ./_site/ "++)
    hostlist = [
                "solar:/var/www/livid.pp.ru/hakyll/",
                "vps.livid.pp.ru:/var/www/"
               ]
