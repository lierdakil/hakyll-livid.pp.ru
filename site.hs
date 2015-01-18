--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Control.Monad
import           Data.Maybe
import           Network.HTTP
import           Hakyll
import           Data.List
import           System.FilePath


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    let postsOnHomePage = 10
    match ("images/*" .||. "files/*") $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- tag pages
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    let tagCloud = tagCloudField "tagCloud" 80 200 tags
    let isActive [] _ = return ""
        isActive args item | myid <- toFilePath $ itemIdentifier item,
                             myid == head args = return "active"
                           | otherwise         = return ""

    tagsRules tags $ \tag pattern -> do
      let title = "Посты с тегом " ++ tag

      route idRoute
      compile $ do
        let posts = loadAllSnapshots pattern "content" >>=
                    recentFirst
        let ctx = constField "title" title `mappend`
                  listField "posts" postCtx posts `mappend`
                  tagCloud `mappend`
                  defaultContext
        makeItem ""
          >>= loadAndApplyTemplate "templates/tags.html" ctx
          >>= loadAndApplyTemplate "templates/default.html" ctx
          >>= relativizeUrls

    match "static/*" $ do
        route   $ setExtension "html"
        let ctx =
                  functionField "is_active" isActive `mappend`
                  tagCloud `mappend`
                  defaultContext
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" ctx
            >>= relativizeUrls

    match "posts/*" $ do
        route   $ setExtension "html"
        compile $ do
          identifier <- getUnderlying
          route' <- getRoute identifier
          let route1 = fromMaybe "undefined" route'
          let spanList _ [] = ([],[])
              spanList func list@(x:xs) =
                                      if func list
                                        then (x:ys,zs)
                                        else ([],list)
                                        where (ys,zs) = spanList func xs
          let breakList func = spanList (not . func)
          let split _ [] = []
              split delim str =
                let (firstline, remainder) = breakList (isPrefixOf delim) str
                in
                firstline : case remainder of
                  [] -> []
                  x -> if x == delim
                    then [[]]
                    else split delim
                    (drop (length delim) x)
          let replace old new = intercalate new . split old
          let postCtx' = constField "url" (replace "%2F" "/" $ urlEncode route1) `mappend`
                          constField "post_id" (toFilePath identifier) `mappend`
                          postCtx
          pandocCompiler
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    postCtx'
            >>= loadAndApplyTemplate "templates/default.html" (tagCloud `mappend` postCtx)
            >>= relativizeUrls

    let navigationField = functionField "navigation" navigationLink
        navigationLink args item = do
                  let filePath = head args
                      text = args !! 1
                      activeClass = args !! 2
                      identifier = fromFilePath filePath
                  Just argUrl <- getRoute identifier
                  let cls =
                        if identifier==itemIdentifier item then
                          activeClass
                        else
                          ""
                  return $
                      "<a href=\""++argUrl++"\""++
                      "class=\""++ cls ++"\"" ++
                      ">"++ text ++"</a>"

    -- archive pages
    let pagePath page = fromFilePath $ "archive/page/"++show (page::PageNumber)++".html"
    archivePaginate <- buildPaginateWith (return.paginateEvery postsOnHomePage.drop postsOnHomePage.reverse) "posts/*" pagePath
    paginateRules archivePaginate $ \pageNum pattern -> do
        route idRoute
        compile $ do
            let posts =
                  loadAllSnapshots pattern "content" >>=
                  recentFirst
            let archiveCtx =
                    listField "posts" postCtx posts     `mappend`
                    constField "title" "Архив"          `mappend`
                    tagCloud `mappend`
                    constField "archive_active" "active" `mappend`
                    paginateContext archivePaginate pageNum `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            archive <- getRoute $ pagePath 1
            let archiveUrl = fromMaybe missingField $ liftM (constField "archiveUrl") archive
            let posts =
                  liftM (take postsOnHomePage) $
                  loadAllSnapshots "posts/*" "content" >>=
                  recentFirst
            let indexCtx =
                    navigationField `mappend`
                    listField "posts" postCtx posts    `mappend`
                    constField "title" "Главная"       `mappend`
                    archiveUrl                         `mappend`
                    tagCloud                           `mappend`
                    functionField "is_active" isActive `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    let feedCtx = postCtx `mappend` bodyField "description"
    let posts = fmap (take 10) . recentFirst =<<
                  loadAllSnapshots "posts/*" "content"
    create ["rss.xml"] $ do
      route idRoute
      compile $ renderRss myFeedConfiguration feedCtx =<< posts
    create ["atom.xml"] $ do
      route idRoute
      compile $ renderAtom myFeedConfiguration feedCtx =<< posts


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y"    `mappend`
    teaserField "teaser" "content"  `mappend`
    field "disqusId" disqusId       `mappend`
    defaultContext
    where
      disqusId = return.fst.splitExtension.toFilePath.itemIdentifier

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
