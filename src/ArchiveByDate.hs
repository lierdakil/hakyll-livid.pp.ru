module ArchiveByDate
(renderArchiveDates, buildArchiveDates, dateTagToStr)
where

import           Utils
import           Hakyll
import           Data.List
import           Data.Function
import           Data.Time.Format                (formatTime)
import           Text.Blaze.Html                 (toHtml, toValue, (!))
import           Text.Blaze.Html.Renderer.String (renderHtml)
import qualified Text.Blaze.Html5                as H
import qualified Text.Blaze.Html5.Attributes     as A
import           Control.Applicative
import           Data.Maybe

data DateInfo = DateInfo {
    diYear  :: Int
  , diMonth :: Int
  , diCount :: Int
  , diUrl   :: String
}

sortByDate :: (MonadMetadata m, MonadFail m) => Identifier -> m [String]
sortByDate x = do
  time <- getItemUTC timeLocale x
  return [formatTime timeLocale "%Y-%m" time]

makeDateInfo :: String -> Int -> String -> DateInfo
makeDateInfo tag =
    uncurry DateInfo (dateTagToYM tag)

renderDates :: [DateInfo] -> String
renderDates ls = foldl (\acc x -> acc ++ showYear x) "" $ reverse years
  where
    years = groupBy ((==) `on` diYear) ls
    showYear dil = renderHtml (H.h1 $ toHtml (diYear $ head dil)) ++ renderHtml (H.ul $ showMonths dil)
    showMonths = foldl (\acc x -> acc >> showMonth x) (toHtml "")
    showMonth di = H.li $ H.a ! A.href (toValue $ diUrl di) $ toHtml $ monthNames !! diMonth di ++ " (" ++ show (diCount di) ++ ")"

renderArchiveDates :: Tags -> Compiler String
renderArchiveDates tags =
  renderDates <$> mapM tagToDI (tagsMap tags)
    where
    tagToDI (tag, ids) =
      (makeDateInfo tag (length ids) . toUrl . fromMaybe "/") <$>
        getRoute (tagsMakeId tags tag)

buildArchiveDates :: (MonadFail m, MonadMetadata m) => Pattern -> (String -> Identifier) -> m Tags
buildArchiveDates = buildTagsWith sortByDate

dateTagToYM :: String -> (Int, Int)
dateTagToYM tag = (year, month)
  where
  month = subtract 1 . read . drop 5 $ tag
  year = read . take 4 $ tag

dateTagToStr :: String -> String
dateTagToStr tag = month ++ " " ++ year
  where
  month = monthNames !! monthNum
  monthNum = snd . dateTagToYM $ tag
  year = show . fst . dateTagToYM $ tag
