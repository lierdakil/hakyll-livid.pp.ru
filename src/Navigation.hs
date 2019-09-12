module Navigation where

import Hakyll
import Data.Maybe
import Utils

navigationField :: Context a
navigationField = functionField "navigation" navigationLink
  where
  navigationLink args item = do
            let filePath = head args
                text = args !! 1
                pattern = maybe (fromList [identifier]) fromRegex $ args !!? 2
                classes = fromMaybe "" $ args !!? 3
                identifier = fromFilePath filePath
                cls = "class=\"" ++(
                      if matches pattern (itemIdentifier item) then
                        "active"
                      else
                        ""
                      )++ classes ++ "\""
            argUrl <- fromJust <$> getRoute identifier
            return $
                "<li "++cls++"><a href=\"/"++argUrl++"\">"++
                text ++"</a></li>"
