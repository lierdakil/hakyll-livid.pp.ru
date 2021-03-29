module Utils where

import Hakyll
import Data.Time

(!!?) :: [[a]] -> Int -> Maybe [a]
list !!? i | i < length list,
             not.null $ list !! i  = Just $ list !! i
           | otherwise = Nothing

recentSnapshots :: Pattern -> Compiler [Item String]
recentSnapshots pattern = loadAllSnapshots pattern "content" >>= recentFirst

pagePath :: Pattern -> String -> PageNumber -> Identifier
pagePath cap name page
  | page == 1 = fromCapture cap   name
  | otherwise = fromCapture cap $ name++"/page/"++show page

sortPaginate :: (Functor f, MonadMetadata f, MonadFail f) => Int -> [Identifier] -> f [[Identifier]]
sortPaginate postsPerPage = fmap (paginateEvery postsPerPage) . sortRecentFirst

tagDeps :: Tags -> [Dependency]
tagDeps t = map (IdentifierDependency . tagsMakeId t . fst) $ tagsMap t

withTagDeps :: Tags -> Rules a -> Rules a
withTagDeps = rulesExtraDependencies . tagDeps

timeLocale :: TimeLocale
timeLocale = defaultTimeLocale {
      wDays = [ ("Понедельник","Пн")
               ,("Вторник"    ,"Вт")
               ,("Среда"      ,"Ср")
               ,("Четверг"    ,"Чт")
               ,("Пятница"    ,"Пт")
               ,("Суббота"    ,"Сб")
               ,("Воскресенье","Вс")],
      months = [ ("Января"  ,"Янв")
                ,("Февраля" ,"Фев")
                ,("Марта"   ,"Мар")
                ,("Апреля"  ,"Апр")
                ,("Мая"     ,"Мая")
                ,("Июня"    ,"Июн")
                ,("Июля"    ,"Июл")
                ,("Августа" ,"Авг")
                ,("Сентября","Сен")
                ,("Октября" ,"Окт")
                ,("Ноября"  ,"Ноя")
                ,("Декабря" ,"Дек")]
}

monthNames :: [String]
monthNames = [
     "Январь"
    ,"Февраль"
    ,"Март"
    ,"Апрель"
    ,"Май"
    ,"Июнь"
    ,"Июль"
    ,"Август"
    ,"Сентябрь"
    ,"Октябрь"
    ,"Ноябрь"
    ,"Декабрь"
    ]
