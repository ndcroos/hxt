-- ------------------------------------------------------------

{- |
   Module     : Text.XML.HXT.Parser.TagSoup
   Copyright  : Copyright (C) 2005 Uwe Schmidt
   License    : MIT

   Maintainer : Uwe Schmidt (uwe@fh-wedel.de)
   Stability  : experimental
   Portability: portable

   lasy HTML and simpe XML parser implemented with tagsoup
   parsing is done with a very simple monadic top down parser

-}

-- ------------------------------------------------------------

module Text.XML.HXT.Parser.TagSoup
    ( parseHtmlTagSoup
    )
where

-- ------------------------------------------------------------

-- The table contains the id map. All element and attribute names are stored
-- the first time they are ecountered, and later always this name is used,
-- not a string built by the parser.

import Text.HTML.TagSoup
import Text.HTML.TagSoup.Entity
    ( lookupNumericEntity
    )

import Text.XML.HXT.DOM.Unicode
    ( isXmlSpaceChar
    )

import Text.XML.HXT.DOM.NamespacePredicates
    ( isWellformedQualifiedName
    )

import Text.XML.HXT.Parser.XmlEntities
    ( -- xmlEntities
    )

import Text.XML.HXT.Parser.XhtmlEntities
    ( xhtmlEntities
    )

import Text.XML.HXT.Parser.HtmlParsec
    ( isEmptyHtmlTag
    , isInnerHtmlTagOf
    , closesHtmlTag
    )

import Text.XML.HXT.Arrow.DOMInterface
    ( XmlTrees
    , QName
    , c_warn
    , mkName
    , mkPrefixLocalPart
    )

import Text.XML.HXT.Arrow.XmlNode
    ( isElem
    , mkError
    , mkCmt
    , mkText
    , mkElement
    , mkAttr
    )

import Data.Maybe

import qualified Data.Map as M

-- ---------------------------------------- 

type Tags	= [Tag]

type NameTable	= M.Map QName QName

data State	= S !Tags !NameTable		-- the name table must be evaluated striktly, else a stack overflow occurs

newtype Parser a = P { parse :: State -> (a, State)}

instance Monad Parser where
    return x	= P $ \ ts -> (x, ts)
    p >>= f	= P $ \ ts -> let
			      (res, ts') = parse p ts
                              in
			      parse (f res) ts'

runParser	:: Parser a -> Tags -> a
runParser p ts	= fst . parse p $ S ts M.empty

-- ----------------------------------------

cond		:: Parser Bool -> Parser a -> Parser a -> Parser a
cond c t e	= do
		  p <- c
		  if p then t else e

lookAhead	:: (Tag -> Bool) -> Parser Bool
lookAhead p	= P $ \ s@(S ts _) -> (not (null ts) && p (head ts), s)

-- ----------------------------------------
-- primitive look ahead tests

isEof		:: Parser Bool
isEof		= P $ \ s@(S ts _) -> (null ts, s)

isText		:: Parser Bool
isText		= lookAhead is
		  where
		  is (TagText _) = True
		  is _		 = False

isCmt		:: Parser Bool
isCmt		= lookAhead is
		  where
		  is (TagComment _) = True
		  is _		    = False

isWarn		:: Parser Bool
isWarn		= lookAhead is
		  where
		  is (TagWarning _) = True
		  is _		    = False

isPos		:: Parser Bool
isPos		= lookAhead is
		  where
		  is (TagPosition _ _) = True
		  is _		 = False

isCls		:: Parser Bool
isCls		= lookAhead is
		  where
		  is (TagClose _) = True
		  is _		  = False

isOpn		:: Parser Bool
isOpn		= lookAhead is
		  where
		  is (TagOpen _ _) = True
		  is _		   = False

-- ----------------------------------------
-- primitive symbol parsers

getTag		:: Parser Tag
getTag		= P $ \ (S (t1:ts1) nt) -> (t1, S ts1 nt)

getSym		:: (Tag -> a) -> Parser a
getSym f	= do
		  t <- getTag
		  return (f t)

getText		:: Parser String
getText		= getSym sym
    		  where
		  sym (TagText t)	= t
		  sym _			= undefined

getCmt		:: Parser String
getCmt		= getSym sym
		  where
		  sym (TagComment c)	= c
	  	  sym _			= undefined

getWarn		:: Parser String
getWarn		= getSym sym
	  	  where
		  sym (TagWarning w)	= w
		  sym _			= undefined

getPos		:: Parser (Int, Int)
getPos		= getSym sym
		  where
		  sym (TagPosition l c)	= (l, c)
		  sym _			= undefined

getCls		:: Parser String
getCls		= getSym sym
		  where
		  sym (TagClose n)	= n
		  sym _			= undefined

getOpn		:: Parser (String, [(String,String)])
getOpn		= getSym sym
		  where
		  sym (TagOpen n al)	= (n, al)
		  sym _			= undefined

-- ----------------------------------------
-- pushback parsers for inserting missing tags

pushBack	:: Tag -> Parser ()
pushBack t	= P $ \ (S ts nt) -> ((), S (t:ts) nt)

insCls		:: String -> Parser ()
insCls n	= pushBack (TagClose n)

insOpn		:: String -> [(String, String)] -> Parser ()
insOpn n al	= pushBack (TagOpen n al)

-- ----------------------------------------

insertQName	:: QName -> Parser QName
insertQName n	= P $ \ (S ts nt) -> let
				     (n', nt') = insert n nt
				     in
				     (n', S ts nt')
		  where
		  insert s nt
		      | isJust r	= (fromJust r, nt)
		      | otherwise	= (s, M.insert s s nt)
		      where
		      r = M.lookup s nt

mkQN		:: String -> Parser QName
mkQN s
    | isSimpleName			= insertQName (mkName s)
    | isWellformedQualifiedName s	= insertQName (mkPrefixLocalPart px lp)
    | otherwise				= insertQName (mkName s)
    where
    isSimpleName	= all (/= ':') s
    (px, (_ : lp))	= span(/= ':') s

-- ----------------------------------------

-- own entity lookup to prevent problems with &amp; and tagsoup hack for IE

lookupEntity	:: Bool -> Bool -> String -> [Tag]
lookupEntity withWarnings _asHtml e0@('#':e)
    = case lookupNumericEntity e of
      Just c  -> [ TagText [c] ]
      Nothing -> ( TagText $ "&" ++ e0 ++ ";") :
		 if withWarnings
		 then [TagWarning $ "illegal char reference: &" ++ e ++ ";"]
		 else []

lookupEntity withWarnings asHtml e
    = case (lookup e entities) of
      Just x  -> [ TagText [toEnum x]]
      Nothing -> (TagText $ "&" ++ e ++ ";") :
		 if withWarnings
		 then [TagWarning $ "Unknown entity reference: &" ++ e ++ ";"]
		 else []
    where
    entities
	| asHtml    = xhtmlEntities
	| otherwise = xhtmlEntities -- xmlEntities (TODO: xhtml is xml and html)

-- ----------------------------------------
-- the main parser

parseHtmlTagSoup	:: Bool -> Bool -> Bool -> Bool -> String -> String -> XmlTrees
parseHtmlTagSoup withWarnings withComment removeWhiteSpace asHtml doc
    = ( docRootElem
	. runParser (buildCont [])
	. ( if asHtml
	    then canonicalizeTags
	    else id
	  )
	. parseTagsOptions (options { optTagWarning   = withWarnings
				    , optLookupEntity = lookupEntity withWarnings asHtml
				    }
			   )
      )
    where
    -- This is essential for lasy parsing:
    -- the call of "take 1" stops parsing, when the first element is detected
    -- no check on end of input sequence is required to build this (0- or 1-element list)
    -- so eof is never checked unneccessarily

    docRootElem
	= take 1 . filter isElem

    wrap		= (:[])

    warn
	| withWarnings	= wrap . mkError c_warn . show . (doc ++) . (" " ++)
	| otherwise	= const []
    cmt
	| withComment	= wrap . mkCmt
	| otherwise	= const []
    txt
	| removeWhiteSpace
			= \ t ->
			  if all isXmlSpaceChar t
			  then []
			  else wrap . mkText $ t
	| otherwise	= wrap . mkText

    isEmptyElem
	| asHtml	= isEmptyHtmlTag
	| otherwise	= const False

    isInnerElem
	| asHtml	= isInnerHtmlTagOf
	| otherwise	= const (const False)

    closesElem
	| asHtml	= \ ns n1 ->
			  not (null ns)
			  &&
			  n1 `closesHtmlTag` (head ns)
	| otherwise	= const (const False)

    buildCont	:: [String] -> Parser XmlTrees
    buildCont ns
	= cond isText ( do
			t <- getText
			rl <- buildCont ns
			return (txt t ++ rl)
		      )
	  ( cond isOpn ( do
			 (n,al) <- getOpn
			 openTag ns n al
		       )
	    ( cond isCls ( do
			   n <- getCls
			   closeTag ns n
			 )
	      ( cond isCmt ( do
			     c <- getCmt
			     rl <- buildCont ns
			     return (cmt c ++ rl)
			   )
		( cond isWarn ( do
				w <- getWarn
				rl <- buildCont ns
				return (warn w ++ rl)
			      )
		  ( cond isPos ( do
				 getPos
				 buildCont ns
			       )
		    ( cond isEof ( do
				   isEof
				   closeAll ns
				 )
		      ( return (warn "parse error in tagsoup tree construction")
		      )
		    )
		  )
		)
	      )
	    )
	  )
	where
	closeTag		:: [String] -> String -> Parser XmlTrees
	closeTag (n':_) n1
	    | n' == n1		= return []			-- a normal closing tag
								-- all other cases try to repair wrong html
	closeTag (ns'@(n':_)) n1				-- n1 closes n implicitly
	    | n' `isInnerElem` n1				-- e.g. <td>...</tr>
				= do
				  insCls n1			-- pushback </n1>
				  insCls n'			-- insert a </n'>
				  buildCont ns'			-- try again
	closeTag ns' n1
	    | isEmptyElem n1	= buildCont ns'			-- ignore a redundant closing tag for empty element
	closeTag ns'@(n':ns1') n1				-- insert a missing closing tag
	    | n1 `elem` ns1'	= do
				  insCls n1
				  insCls n'
				  rl <- buildCont ns'
				  return ( warn ("closing tag " ++ show n' ++
						 " expected, but " ++ show n1 ++ " found")
					   ++ rl
					 )
	closeTag ns' n1						-- ignore a wrong closing tag
				= do
				  rl <- buildCont ns'
				  return ( warn ("no opening tag for closing tag " ++ show n1)
					   ++ rl
					 )

	openTag			:: [String] -> String -> [(String, String)] -> Parser XmlTrees
	openTag ns' n1 al1
	    | isPiDT n1		= buildCont ns'
	    | isEmptyElem n1
				= do
				  qn <- mkQN n1
				  al <- mkAttrs al1
				  rl <- buildCont ns'
				  return (mkElement qn al [] : rl)
	    | closesElem ns' n1	= do
				  insOpn n1 al1
				  insCls (head ns')
				  buildCont ns'
	    | otherwise		= do
				  qn <- mkQN n1
				  al <- mkAttrs al1
				  cs <- buildCont (n1:ns')
				  rl <- buildCont ns'
				  return (mkElement qn al cs : rl)
	    where
	    isPiDT ('?':_)	= True
	    isPiDT ('!':_)	= True
	    isPiDT _		= False
	    mkAttrs		= mapM (uncurry mkA)
	    mkA an av		= do
				  qan <- mkQN an
				  return (mkAttr qan (wrap . mkText $ av))

	closeAll		:: [String] -> Parser XmlTrees
	closeAll ns'		= return (concatMap wrn ns')
				  where
				  wrn = warn . ("insert missing closing tag " ++) . show

-- ------------------------------------------------------------
