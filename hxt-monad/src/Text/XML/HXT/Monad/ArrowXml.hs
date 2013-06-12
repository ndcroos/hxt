{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- hack: {-# LANGUAGE MultiParamTypeClasses #-} is necessary for stylish haskell

-- ------------------------------------------------------------

{- |
   Basic arrows for processing XML documents
-}

-- ------------------------------------------------------------

module Text.XML.HXT.Monad.ArrowXml
    ( module Text.XML.HXT.Monad.ArrowXml )
where

import           Control.Monad.Arrow
import           Control.Monad.ArrowIf
import           Control.Monad.ArrowList
import           Control.Monad.ArrowTree
import           Control.Monad.MonadSequence

import           Data.Char.Properties.XMLCharProps (isXmlSpaceChar)
import           Data.Maybe

import           Text.XML.HXT.DOM.Interface
import qualified Text.XML.HXT.DOM.ShowXml          as XS
import qualified Text.XML.HXT.DOM.XmlNode          as XN

-- ------------------------------------------------------------

{- | Arrows in monadic form for processing 'Text.XML.HXT.DOM.TypeDefs.XmlTree's

These arrows can be grouped into predicates, selectors, constructors, and transformers.

All predicates (tests) act like 'Control.Arrow.ArrowIf.none' for failure and 'Control.Arrow.ArrowIf.this' for success.
A logical and can be formed by @ a1 >>> a2 @, a locical or by @ a1 \<+\> a2 @.

Selector arrows will fail, when applied to wrong input, e.g. selecting the text of a node with 'getText'
will fail when applied to a none text node.

Edit arrows will remain the input unchanged, when applied to wrong argument, e.g. editing the content of a text node
with 'changeText' applied to an element node will return the unchanged element node.
-}

-- infixl 7 +=

-- discriminating predicates

-- | test for text nodes
isText              :: (MonadList s m) => XmlTree -> m XmlTree
isText              = isA XN.isText
{-# INLINE isText #-}

isBlob              :: (MonadList s m) => XmlTree -> m XmlTree
isBlob              = isA XN.isBlob
{-# INLINE isBlob #-}

-- | test for char reference, used during parsing
isCharRef           :: (MonadList s m) => XmlTree -> m XmlTree
isCharRef           = isA XN.isCharRef
{-# INLINE isCharRef #-}

-- | test for entity reference, used during parsing
isEntityRef         :: (MonadList s m) => XmlTree -> m XmlTree
isEntityRef         = isA XN.isEntityRef
{-# INLINE isEntityRef #-}

-- | test for comment
isCmt               :: (MonadList s m) => XmlTree -> m XmlTree
isCmt               = isA XN.isCmt
{-# INLINE isCmt #-}

-- | test for CDATA section, used during parsing
isCdata             :: (MonadList s m) => XmlTree -> m XmlTree
isCdata             = isA XN.isCdata
{-# INLINE isCdata #-}

-- | test for processing instruction
isPi                :: (MonadList s m) => XmlTree -> m XmlTree
isPi                = isA XN.isPi
{-# INLINE isPi #-}

-- | test for processing instruction \<?xml ...\>
isXmlPi             :: (MonadList s m) => XmlTree -> m XmlTree
isXmlPi             = isPi >=> hasName "xml"

-- | test for element
isElem              :: (MonadList s m) => XmlTree -> m XmlTree
isElem              = isA XN.isElem
{-# INLINE isElem #-}

-- | test for DTD part, used during parsing
isDTD               :: (MonadList s m) => XmlTree -> m XmlTree
isDTD               = isA XN.isDTD
{-# INLINE isDTD #-}

-- | test for attribute tree
isAttr              :: (MonadList s m) => XmlTree -> m XmlTree
isAttr              = isA XN.isAttr
{-# INLINE isAttr #-}

-- | test for error message
isError             :: (MonadList s m) => XmlTree -> m XmlTree
isError             = isA XN.isError
{-# INLINE isError #-}

-- | test for root node (element with name \"\/\")
isRoot              :: (MonadList s m) => XmlTree -> m XmlTree
isRoot              = isA XN.isRoot
{-# INLINE isRoot #-}

-- | test for text nodes with text, for which a predicate holds
--
-- example: @hasText (all (\`elem\` \" \\t\\n\"))@ check for text nodes with only whitespace content

hasText             :: (MonadList s m) => (String -> Bool) -> XmlTree -> m XmlTree
hasText p           = (isText >=> getText >=> isA p) `guards` this

-- | test for text nodes with only white space
--
-- implemented with 'hasTest'

isWhiteSpace        :: (MonadList s m) => XmlTree -> m XmlTree
isWhiteSpace        = hasText (all isXmlSpaceChar)
{-# INLINE isWhiteSpace #-}

-- |
-- test whether a node (element, attribute, pi) has a name with a special property

hasNameWith         :: (MonadList s m) => (QName  -> Bool) -> XmlTree -> m XmlTree
hasNameWith p       = (getQName        >=> isA p) `guards` this
{-# INLINE hasNameWith #-}

-- |
-- test whether a node (element, attribute, pi) has a specific qualified name
-- useful only after namespace propagation
hasQName            :: (MonadList s m) => QName  -> XmlTree -> m XmlTree
hasQName n          = (getQName        >=> isA (== n)) `guards` this
{-# INLINE hasQName #-}

-- |
-- test whether a node has a specific name (prefix:localPart ore localPart),
-- generally useful, even without namespace handling
hasName             :: (MonadList s m) => String -> XmlTree -> m XmlTree
hasName n           = (getName         >=> isA (== n)) `guards` this
{-# INLINE hasName #-}

-- |
-- test whether a node has a specific name as local part,
-- useful only after namespace propagation
hasLocalPart        :: (MonadList s m) => String -> XmlTree -> m XmlTree
hasLocalPart n      = (getLocalPart    >=> isA (== n)) `guards` this
{-# INLINE hasLocalPart #-}

-- |
-- test whether a node has a specific name prefix,
-- useful only after namespace propagation
hasNamePrefix       :: (MonadList s m) => String -> XmlTree -> m XmlTree
hasNamePrefix n     = (getNamePrefix   >=> isA (== n)) `guards` this
{-# INLINE hasNamePrefix #-}

-- |
-- test whether a node has a specific namespace URI
-- useful only after namespace propagation
hasNamespaceUri     :: (MonadList s m) => String -> XmlTree -> m XmlTree
hasNamespaceUri n   = (getNamespaceUri >=> isA (== n)) `guards` this
{-# INLINE hasNamespaceUri #-}

-- |
-- test whether an element node has an attribute node with a specific name
hasAttr             :: (MonadList s m) => String -> XmlTree -> m XmlTree
hasAttr n           = (getAttrl        >=> hasName n)  `guards` this
{-# INLINE hasAttr #-}

-- |
-- test whether an element node has an attribute node with a specific qualified name
hasQAttr            :: (MonadList s m) => QName -> XmlTree -> m XmlTree
hasQAttr n          = (getAttrl        >=> hasQName n)  `guards` this
{-# INLINE hasQAttr #-}

-- |
-- test whether an element node has an attribute with a specific value
hasAttrValue        :: (MonadList s m) => String -> (String -> Bool) -> XmlTree -> m XmlTree
hasAttrValue n p    = (getAttrl >=> hasName n >=> xshow getChildren >=> isA p)  `guards` this

-- |
-- test whether an element node has an attribute with a qualified name and a specific value
hasQAttrValue       :: (MonadList s m) => QName -> (String -> Bool) -> XmlTree -> m XmlTree
hasQAttrValue n p   = (getAttrl >=> hasQName n >=> xshow getChildren >=> isA p)  `guards` this

-- constructor arrows ------------------------------------------------------------

-- | text node construction arrow
mkText              :: (MonadList s m) => String -> m XmlTree
mkText              = arr  XN.mkText
{-# INLINE mkText #-}

-- | blob node construction arrow
mkBlob              :: (MonadList s m) => Blob -> m XmlTree
mkBlob              = arr  XN.mkBlob
{-# INLINE mkBlob #-}

-- | char reference construction arrow, useful for document output
mkCharRef           :: (MonadList s m) => Int -> m XmlTree
mkCharRef           = arr  XN.mkCharRef
{-# INLINE mkCharRef #-}

-- | entity reference construction arrow, useful for document output
mkEntityRef         :: (MonadList s m) => String -> m XmlTree
mkEntityRef         = arr  XN.mkEntityRef
{-# INLINE mkEntityRef #-}

-- | comment node construction, useful for document output
mkCmt               :: (MonadList s m) => String -> m XmlTree
mkCmt               = arr  XN.mkCmt
{-# INLINE mkCmt #-}

-- | CDATA construction, useful for document output
mkCdata             :: (MonadList s m) => String -> m XmlTree
mkCdata             = arr  XN.mkCdata
{-# INLINE mkCdata #-}

-- | error node construction, useful only internally
mkError             :: (MonadList s m) => Int -> String -> m XmlTree
mkError level       = arr (XN.mkError level)

-- | element construction:
-- | the attributes and the content of the element are computed by applying arrows
-- to the input
mkElement           :: (MonadList s m) => QName -> (n -> m XmlTree) -> (n -> m XmlTree) -> (n -> m XmlTree)
mkElement n af cf   = (listA af &&& listA cf)
                      >=>
                      arr2 (\ al cl -> XN.mkElement n al cl)

-- | attribute node construction:
-- | the attribute value is computed by applying an arrow to the input
mkAttr              :: (MonadList s m) => QName -> (n -> m XmlTree) -> (n -> m XmlTree)
mkAttr qn f         = listA f >=> arr (XN.mkAttr qn)

-- | processing instruction construction:
-- | the content of the processing instruction is computed by applying an arrow to the input
mkPi                :: (MonadList s m) => QName -> (n -> m XmlTree) -> (n -> m XmlTree)
mkPi qn f           = listA f >=> arr (XN.mkPi   qn)

-- convenient arrows for constructors --------------------------------------------------

-- | convenient arrow for element construction, more comfortable variant of 'mkElement'
--
-- example for simplifying 'mkElement' :
--
-- > mkElement qn (a1 <+> ... <+> ai) (c1 <+> ... <+> cj)
--
-- equals
--
-- > mkqelem qn [a1,...,ai] [c1,...,cj]

mkqelem             :: (MonadList s m) => QName -> [n -> m XmlTree] -> [n -> m XmlTree] -> (n -> m XmlTree)
mkqelem  n afs cfs  = mkElement n (catA afs) (catA cfs)
{-# INLINE mkqelem #-}

-- | convenient arrow for element construction with strings instead of
-- qualified names as element names, see also 'mkElement' and 'mkelem'
mkelem              :: (MonadList s m) => String -> [n -> m XmlTree] -> [n -> m XmlTree] -> (n -> m XmlTree)
mkelem  n afs cfs   = mkElement (mkName n) (catA afs) (catA cfs)
{-# INLINE mkelem #-}

-- | convenient arrow for element constrution with attributes but without content,
-- simple variant of 'mkelem' and 'mkElement'
aelem               :: (MonadList s m) => String -> [n -> m XmlTree] -> (n -> m XmlTree)
aelem n afs         = catA afs >. \ al -> XN.mkElement (mkName n) al []
{-# INLINE aelem #-}

-- | convenient arrow for simple element constrution without attributes,
-- simple variant of 'mkelem' and 'mkElement'
selem               :: (MonadList s m) => String -> [n -> m XmlTree] -> (n -> m XmlTree)
selem n cfs         = catA cfs >.         XN.mkElement (mkName n) []
{-# INLINE selem #-}

-- | convenient arrow for constrution of empty elements without attributes,
-- simple variant of 'mkelem' and 'mkElement'
eelem               :: (MonadList s m) => String -> (n -> m XmlTree)
eelem n             = constA      (XN.mkElement (mkName n) [] [])
{-# INLINE eelem #-}

-- | construction of an element node with name \"\/\" for document roots
root                :: (MonadList s m) => [n -> m XmlTree] -> [n -> m XmlTree] -> n -> m XmlTree
root                = mkelem t_root
{-# INLINE root #-}

-- | alias for 'mkAttr'
qattr               :: (MonadList s m) => QName -> (n -> m XmlTree) -> (n -> m XmlTree)
qattr               = mkAttr
{-# INLINE qattr #-}

-- | convenient arrow for attribute constrution, simple variant of 'mkAttr'
attr                :: (MonadList s m) => String -> (n -> m XmlTree) -> (n -> m XmlTree)
attr                = mkAttr . mkName
{-# INLINE attr #-}

-- constant arrows (ignoring the input) for tree construction ------------------------------

-- | constant arrow for text nodes
txt                 :: (MonadList s m) => String -> n -> m XmlTree
txt                 = constA .  XN.mkText
{-# INLINE txt #-}

-- | constant arrow for blob nodes
blb                 :: (MonadList s m) => Blob -> n -> m XmlTree
blb                 = constA .  XN.mkBlob
{-# INLINE blb #-}

-- | constant arrow for char reference nodes
charRef             :: (MonadList s m) => Int -> n -> m XmlTree
charRef             = constA .  XN.mkCharRef
{-# INLINE charRef #-}

-- | constant arrow for entity reference nodes
entityRef           :: (MonadList s m) => String -> n -> m XmlTree
entityRef           = constA .  XN.mkEntityRef
{-# INLINE entityRef #-}

-- | constant arrow for comment
cmt                 :: (MonadList s m) => String -> n -> m XmlTree
cmt                 = constA .  XN.mkCmt
{-# INLINE cmt #-}

-- | constant arrow for warning
warn                :: (MonadList s m) => String -> n -> m XmlTree
warn                = constA . (XN.mkError c_warn)
{-# INLINE warn #-}

-- | constant arrow for errors
err                 :: (MonadList s m) => String -> n -> m XmlTree
err                 = constA . (XN.mkError c_err)
{-# INLINE err #-}

-- | constant arrow for fatal errors
fatal               :: (MonadList s m) => String -> n -> m XmlTree
fatal               = constA . (XN.mkError c_fatal)
{-# INLINE fatal #-}

-- | constant arrow for simple processing instructions, see 'mkPi'
spi                 :: (MonadList s m) => String -> String -> n -> m XmlTree
spi piName piCont   = constA (XN.mkPi (mkName piName) [XN.mkAttr (mkName a_value) [XN.mkText piCont]])
{-# INLINE spi #-}

-- | constant arrow for attribute nodes, attribute name is a qualified name and value is a text,
-- | see also 'mkAttr', 'qattr', 'attr'
sqattr              :: (MonadList s m) => QName -> String -> n -> m XmlTree
sqattr an av        = constA (XN.mkAttr an                 [XN.mkText av])
{-# INLINE sqattr #-}

-- | constant arrow for attribute nodes, attribute name and value are
-- | given by parameters, see 'mkAttr'
sattr               :: (MonadList s m) => String -> String -> n -> m XmlTree
sattr an av         = constA (XN.mkAttr (mkName an)     [XN.mkText av])
{-# INLINE sattr #-}
-- -}
    -- selector arrows --------------------------------------------------

-- | select the text of a text node
getText             :: (MonadList s m) => XmlTree -> m String
getText             = arrL (maybeToList  . XN.getText)
{-# INLINE getText #-}

-- | select the value of a char reference
getCharRef          :: (MonadList s m) => XmlTree -> m Int
getCharRef          = arrL (maybeToList  . XN.getCharRef)
{-# INLINE getCharRef #-}

-- | select the name of a entity reference node
getEntityRef        :: (MonadList s m) => XmlTree -> m String
getEntityRef        = arrL (maybeToList  . XN.getEntityRef)
{-# INLINE getEntityRef #-}

-- | select the comment of a comment node
getCmt              :: (MonadList s m) => XmlTree -> m String
getCmt              = arrL (maybeToList  . XN.getCmt)
{-# INLINE getCmt #-}

-- | select the content of a CDATA node
getCdata            :: (MonadList s m) => XmlTree -> m String
getCdata            = arrL (maybeToList  . XN.getCdata)
{-# INLINE getCdata #-}

-- | select the name of a processing instruction
getPiName           :: (MonadList s m) => XmlTree -> m QName
getPiName           = arrL (maybeToList  . XN.getPiName)
{-# INLINE getPiName #-}

-- | select the content of a processing instruction
getPiContent        :: (MonadList s m) => XmlTree -> m XmlTree
getPiContent        = arrL (fromMaybe [] . XN.getPiContent)
{-# INLINE getPiContent #-}

-- | select the name of an element node
getElemName         :: (MonadList s m) => XmlTree -> m QName
getElemName         = arrL (maybeToList  . XN.getElemName)
{-# INLINE getElemName #-}

-- | select the attribute list of an element node
getAttrl            :: (MonadList s m) => XmlTree -> m XmlTree
getAttrl            = arrL (fromMaybe [] . XN.getAttrl)
{-# INLINE getAttrl #-}

-- | select the DTD type of a DTD node
getDTDPart          :: (MonadList s m) => XmlTree -> m DTDElem
getDTDPart          = arrL (maybeToList  . XN.getDTDPart)
{-# INLINE getDTDPart #-}

-- | select the DTD attributes of a DTD node
getDTDAttrl         :: (MonadList s m) => XmlTree -> m Attributes
getDTDAttrl         = arrL (maybeToList  . XN.getDTDAttrl)
{-# INLINE getDTDAttrl #-}

-- | select the name of an attribute
getAttrName         :: (MonadList s m) => XmlTree -> m QName
getAttrName         = arrL (maybeToList  . XN.getAttrName)
{-# INLINE getAttrName #-}

-- | select the error level (c_warn, c_err, c_fatal) from an error node
getErrorLevel       :: (MonadList s m) => XmlTree -> m Int
getErrorLevel       = arrL (maybeToList  . XN.getErrorLevel)
{-# INLINE getErrorLevel #-}

-- | select the error message from an error node
getErrorMsg         :: (MonadList s m) => XmlTree -> m String
getErrorMsg         = arrL (maybeToList  . XN.getErrorMsg)
{-# INLINE getErrorMsg #-}

-- | select the qualified name from an element, attribute or pi
getQName            :: (MonadList s m) => XmlTree -> m QName
getQName            = arrL (maybeToList  . XN.getName)
{-# INLINE getQName #-}

-- | select the prefix:localPart or localPart from an element, attribute or pi
getName             :: (MonadList s m) => XmlTree -> m String
getName             = arrL (maybeToList  . XN.getQualifiedName)
{-# INLINE getName #-}

-- | select the univeral name ({namespace URI} ++ localPart)
getUniversalName    :: (MonadList s m) => XmlTree -> m String
getUniversalName    = arrL (maybeToList  . XN.getUniversalName)
{-# INLINE getUniversalName #-}

-- | select the univeral name (namespace URI ++ localPart)
getUniversalUri     :: (MonadList s m) => XmlTree -> m String
getUniversalUri     = arrL (maybeToList  . XN.getUniversalUri)
{-# INLINE getUniversalUri #-}

-- | select the local part
getLocalPart        :: (MonadList s m) => XmlTree -> m String
getLocalPart        = arrL (maybeToList  . XN.getLocalPart)
{-# INLINE getLocalPart #-}

-- | select the name prefix
getNamePrefix       :: (MonadList s m) => XmlTree -> m String
getNamePrefix       = arrL (maybeToList  . XN.getNamePrefix)
{-# INLINE getNamePrefix #-}

-- | select the namespace URI
getNamespaceUri     :: (MonadList s m) => XmlTree -> m String
getNamespaceUri     = arrL (maybeToList  . XN.getNamespaceUri)
{-# INLINE getNamespaceUri #-}

-- | select the value of an attribute of an element node,
-- always succeeds with empty string as default value \"\"
getAttrValue        :: (MonadList s m) => String -> XmlTree -> m String
getAttrValue n      = xshow (getAttrl >=> hasName n >=> getChildren)

-- | like 'getAttrValue', but fails if the attribute does not exist
getAttrValue0       :: (MonadList s m) => String -> XmlTree -> m String
getAttrValue0 n     = getAttrl >=> hasName n >=> xshow getChildren

-- | like 'getAttrValue', but select the value of an attribute given by a qualified name,
-- always succeeds with empty string as default value \"\"
getQAttrValue       :: (MonadList s m) => QName -> XmlTree -> m String
getQAttrValue n     = xshow (getAttrl >=> hasQName n >=> getChildren)

-- | like 'getQAttrValue', but fails if attribute does not exist
getQAttrValue0      :: (MonadList s m) => QName -> XmlTree -> m String
getQAttrValue0 n    = getAttrl >=> hasQName n >=> xshow getChildren

-- edit arrows --------------------------------------------------

-- | edit the string of a text node
changeText          :: (MonadList s m) => (String -> String) -> XmlTree -> m XmlTree
changeText cf       = arr (XN.changeText     cf) `when` isText

-- | edit the blob of a blob node
changeBlob          :: (MonadList s m) => (Blob -> Blob) -> XmlTree -> m XmlTree
changeBlob cf       = arr (XN.changeBlob     cf) `when` isBlob

-- | edit the comment string of a comment node
changeCmt           :: (MonadList s m) => (String -> String) -> XmlTree -> m XmlTree
changeCmt  cf       = arr (XN.changeCmt      cf) `when` isCmt

-- | edit an element-, attribute- or pi- name
changeQName         :: (MonadList s m) => (QName  -> QName) -> XmlTree -> m XmlTree
changeQName cf      = arr (XN.changeName  cf) `when` getQName

-- | edit an element name
changeElemName      :: (MonadList s m) => (QName  -> QName) -> XmlTree -> m XmlTree
changeElemName cf   = arr (XN.changeElemName  cf) `when` isElem

-- | edit an attribute name
changeAttrName      :: (MonadList s m) => (QName  -> QName) -> XmlTree -> m XmlTree
changeAttrName cf   = arr (XN.changeAttrName cf) `when` isAttr

-- | edit a pi name
changePiName        :: (MonadList s m) => (QName  -> QName) -> XmlTree -> m XmlTree
changePiName cf     = arr (XN.changePiName  cf) `when` isPi

-- | edit an attribute value
changeAttrValue     :: (MonadList s m) => (String -> String) -> XmlTree -> m XmlTree
changeAttrValue cf  = replaceChildren ( xshow getChildren
                                        >=> arr cf
                                        >=> mkText
                                      )
                      `when` isAttr


-- | edit an attribute list of an element node
changeAttrl         :: (MonadList s m) =>
                       (XmlTrees -> XmlTrees -> XmlTrees) ->
                       (XmlTree -> m XmlTree) ->
                       XmlTree -> m XmlTree
changeAttrl cf f    = ( ( listA f &&& this )
                        >=>
                        arr2 changeAL
                      )
                      `when`
                      ( isElem <+> isPi )
    where
      changeAL as x = XN.changeAttrl (\ xs -> cf xs as) x

-- | replace an element, attribute or pi name
setQName            :: (MonadList s m) => QName -> XmlTree -> m XmlTree
setQName  n         = changeQName  (const n)
{-# INLINE setQName #-}

-- | replace an element name
setElemName         :: (MonadList s m) => QName -> XmlTree -> m XmlTree
setElemName  n      = changeElemName  (const n)
{-# INLINE setElemName #-}

-- | replace an attribute name
setAttrName         :: (MonadList s m) => QName -> XmlTree -> m XmlTree
setAttrName n       = changeAttrName (const n)
{-# INLINE setAttrName #-}

-- | replace an element name
setPiName           :: (MonadList s m) => QName -> XmlTree -> m XmlTree
setPiName  n        = changePiName  (const n)
{-# INLINE setPiName #-}

-- | replace an atribute list of an element node
setAttrl            :: (MonadList s m) => (XmlTree -> m XmlTree) -> XmlTree -> m XmlTree
setAttrl            = changeAttrl (const id)                -- (\ x y -> y)
{-# INLINE setAttrl #-}

-- | add a list of attributes to an element
addAttrl            :: (MonadList s m) => (XmlTree -> m XmlTree) -> XmlTree -> m XmlTree
addAttrl            = changeAttrl (XN.mergeAttrl)
{-# INLINE addAttrl #-}

-- | add (or replace) an attribute
addAttr             :: (MonadList s m) => String -> String  -> XmlTree -> m XmlTree
addAttr an av       = addAttrl (sattr an av)
{-# INLINE addAttr #-}

-- | remove an attribute
removeAttr          :: (MonadList s m) => String  -> XmlTree -> m XmlTree
removeAttr an       = processAttrl (none `when` hasName an)

-- | remove an attribute with a qualified name
removeQAttr         :: (MonadList s m) => QName  -> XmlTree -> m XmlTree
removeQAttr an      = processAttrl (none `when` hasQName an)

-- | process the attributes of an element node with an arrow
processAttrl        :: (MonadList s m) => (XmlTree -> m XmlTree) -> XmlTree -> m XmlTree
processAttrl f      = setAttrl (getAttrl >=> f)

-- | process a whole tree inclusive attribute list of element nodes
-- see also: 'Control.Arrow.ArrowTree.processTopDown'

processTopDownWithAttrl     :: (MonadList s m) => (XmlTree -> m XmlTree) -> XmlTree -> m XmlTree
processTopDownWithAttrl f   = processTopDown ( f >=> ( processAttrl (processTopDown f) `when` isElem))

    -- | convenient op for adding attributes or children to a node
    --
    -- usage: @ tf += cf @
    --
    -- the @tf@ arrow computes an element node, and all trees computed by @cf@ are
    -- added to this node, if a tree is an attribute, it is inserted in the attribute list
    -- else it is appended to the content list.
    --
    -- attention: do not build long content list this way because '+=' is implemented by ++
    --
    -- examples:
    --
    -- > eelem "a"
    -- >   += sattr "href" "page.html"
    -- >   += sattr "name" "here"
    -- >   += txt "look here"
    --
    -- is the same as
    --
    -- > mkelem [ sattr "href" "page.html"
    -- >        , sattr "name" "here"
    -- >        ]
    -- >        [ txt "look here" ]
    --
    -- and results in the XML fragment: \<a href=\"page.html\" name=\"here\"\>look here\<\/a\>
    --
    -- advantage of the '+=' operator is, that attributes and content can be added
    -- any time step by step.
    -- if @tf@ computes a whole list of trees, e.g. a list of \"td\" or \"tr\" elements,
    -- the attributes or content is added to all trees. useful for adding \"class\" or \"style\" attributes
    -- to table elements.

(+=)                :: (MonadList s m) => (b -> m XmlTree) -> (b -> m XmlTree) -> b -> m XmlTree
tf += cf            = (tf &&& listA cf) >=> arr2 addChildren
                      where
                        addChildren     :: XmlTree -> XmlTrees -> XmlTree
                        addChildren t cs
                            = foldl addChild t cs
                        addChild        :: XmlTree -> XmlTree -> XmlTree
                        addChild t c
                            | not (XN.isElem t)
                                = t
                            | XN.isAttr c
                                = XN.changeAttrl (XN.addAttr c) t
                            | otherwise
                                = XN.changeChildren (++ [c]) t


-- | apply an arrow to the input and convert the resulting XML trees into a string representation

xshow               :: (MonadList s m) => (n -> m XmlTree) -> (n -> m String)
xshow f             = f >. XS.xshow
{-# INLINE xshow #-}


-- | apply an arrow to the input and convert the resulting XML trees into a string representation

xshowBlob           :: (MonadList s m) => (n -> m XmlTree) -> (n -> m Blob)
xshowBlob f         = f >. XS.xshowBlob
{-# INLINE xshowBlob #-}

{- | Document Type Definition arrows

These are separated, because they are not needed for document processing,
only when processing the DTD, e.g. for generating access funtions for the toolbox
from a DTD (se example DTDtoHaskell in the examples directory)
-}

isDTDDoctype        :: (MonadList s m) => XmlTree -> m XmlTree
isDTDDoctype        = isA (maybe False (== DOCTYPE ) . XN.getDTDPart)

isDTDElement        :: (MonadList s m) => XmlTree -> m XmlTree
isDTDElement        = isA (maybe False (== ELEMENT ) . XN.getDTDPart)

isDTDContent        :: (MonadList s m) => XmlTree -> m XmlTree
isDTDContent        = isA (maybe False (== CONTENT ) . XN.getDTDPart)

isDTDAttlist        :: (MonadList s m) => XmlTree -> m XmlTree
isDTDAttlist        = isA (maybe False (== ATTLIST ) . XN.getDTDPart)

isDTDEntity         :: (MonadList s m) => XmlTree -> m XmlTree
isDTDEntity         = isA (maybe False (== ENTITY  ) . XN.getDTDPart)

isDTDPEntity        :: (MonadList s m) => XmlTree -> m XmlTree
isDTDPEntity        = isA (maybe False (== PENTITY ) . XN.getDTDPart)

isDTDNotation       :: (MonadList s m) => XmlTree -> m XmlTree
isDTDNotation       = isA (maybe False (== NOTATION) . XN.getDTDPart)

isDTDCondSect       :: (MonadList s m) => XmlTree -> m XmlTree
isDTDCondSect       = isA (maybe False (== CONDSECT) . XN.getDTDPart)

isDTDName           :: (MonadList s m) => XmlTree -> m XmlTree
isDTDName           = isA (maybe False (== NAME    ) . XN.getDTDPart)

isDTDPERef          :: (MonadList s m) => XmlTree -> m XmlTree
isDTDPERef          = isA (maybe False (== PEREF   ) . XN.getDTDPart)

hasDTDAttr          :: (MonadList s m) => String -> XmlTree -> m XmlTree
hasDTDAttr n        = isA (isJust . lookup n . fromMaybe [] . XN.getDTDAttrl)

getDTDAttrValue     :: (MonadList s m) => String -> XmlTree -> m String
getDTDAttrValue n   = arrL (maybeToList . lookup n . fromMaybe [] . XN.getDTDAttrl)

setDTDAttrValue     :: (MonadList s m) => String -> String -> XmlTree -> m XmlTree
setDTDAttrValue n v = arr (XN.changeDTDAttrl (addEntry n v)) `when` isDTD

mkDTDElem           :: (MonadList s m) => DTDElem -> Attributes -> (n -> m XmlTree) -> (n -> m XmlTree)
mkDTDElem e al cf   = listA cf >=> arr (XN.mkDTDElem e al)

mkDTDDoctype        :: (MonadList s m) => Attributes -> (n -> m XmlTree) -> (n -> m XmlTree)
mkDTDDoctype        = mkDTDElem DOCTYPE

mkDTDElement        :: (MonadList s m) => Attributes -> (n -> m XmlTree)
mkDTDElement al     = mkDTDElem ELEMENT al none

mkDTDEntity         :: (MonadList s m) => Attributes -> (n -> m XmlTree)
mkDTDEntity al      = mkDTDElem ENTITY al none

mkDTDPEntity        :: (MonadList s m) => Attributes -> (n -> m XmlTree)
mkDTDPEntity al     = mkDTDElem PENTITY al none

-- ------------------------------------------------------------