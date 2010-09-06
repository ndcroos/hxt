-- ------------------------------------------------------------

{- |
   Module     : Text.XML.HXT.Arrow.LibCurlInput
   Copyright  : Copyright (C) 2005 Uwe Schmidt
   License    : MIT

   Maintainer : Uwe Schmidt (uwe@fh-wedel.de)
   Stability  : experimental
   Portability: portable

   libcurl input
-}

-- ------------------------------------------------------------

module Text.XML.HXT.Arrow.LibCurlInput
    ( getLibCurlContents
    , a_use_curl
    , withCurl
    , curlSysConfigOptions
    )
where

import           Control.Arrow                            -- arrow classes
import           Control.Arrow.ArrowList
import           Control.Arrow.ArrowTree
import           Control.Arrow.ArrowIO

import           System.Console.GetOpt

import           Text.XML.HXT.Arrow.DocumentInput		( addInputError )
import qualified Text.XML.HXT.IO.GetHTTPLibCurl as LibCURL

import           Text.XML.HXT.DOM.Interface

import           Text.XML.HXT.Arrow.XmlArrow
import           Text.XML.HXT.Arrow.XmlState

-- ----------------------------------------------------------

getLibCurlContents	:: IOSArrow XmlTree XmlTree
getLibCurlContents
    = getC
      $<<
      ( getAttrValue transferURI
        &&&
        getSysParam (theInputOptions `pairS`
                     (theRedirect `pairS`
                      (theProxy `pairS`
                       theStrictInput
                      )
                     )
                    )
      )
      where
      getC uri (options, (redirect, (proxy, strictInput)))
          = applyA ( ( traceMsg 2 ( "get HTTP via libcurl, uri=" ++ show uri ++ " options=" ++ show options )
                       >>>
                       arrIO0 ( LibCURL.getCont
                                    strictInput
                                    ((a_proxy, proxy) : (a_redirect, show . fromEnum $ redirect) : options)
                                    uri
                              )
                     )
                     >>>
                     ( arr (uncurry addInputError)
                       |||
                       arr addContent
                     )
                   )

addContent        :: (Attributes, String) -> IOSArrow XmlTree XmlTree
addContent (al, c)
    = replaceChildren (txt c)		-- add the contents
      >>>
      seqA (map (uncurry addAttr) al)	-- add the meta info (HTTP headers, ...)

-- ------------------------------------------------------------

a_use_curl			:: String
a_use_curl                      = "use-curl"

withCurl                        :: Attributes -> SysConfig
withCurl curlOptions            = putS (theUseCurl `pairS` theHttpHandler) (True, getLibCurlContents)
                                  >>>
                                  withInputOptions curlOptions

curlSysConfigOptions            :: [OptDescr SysConfig]
curlSysConfigOptions
    = [ Option "" [a_use_curl]  (NoArg (withCurl []))  "enable HTTP input with libcurl" ]

-- ------------------------------------------------------------
