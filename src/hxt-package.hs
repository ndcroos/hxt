module Main
where

import System.Environment

part1, part2, part3a, part3b, modules, part4a, part4b :: [String]

part1
    = [ "-- arch-tag: Haskell XML Toolbox main description file"
      , "name: hxt"
      ]

version	:: String
version
    = "version: "

part2
    = [ "license: OtherLicense"
      , "license-file: LICENCE"
      , "maintainer: Uwe Schmidt <uwe@fh-wedel.de>"
      , "stability: stable"
      , "category: XML"
      , "synopsis: A collection of tools for processing XML with Haskell. "
      , "description:  The Haskell XML Toolbox bases on the ideas of HaXml and HXML," ++
	" but introduces a more general approach for processing XML with Haskell. The Haskell XML Toolbox" ++
	" uses a generic data model for representing XML documents, including the DTD subset and the document" ++
	" subset, in Haskell. It contains a validating XML parser, a HTML parser, namespace support," ++
	" an XPath expression evaluator, an XSLT library, a RelaxNG schema validator" ++
	" and funtions for serialization and deserialization of user defined data." ++
	" The libraray make extensive use of the arrow approach for processing XML."
      , "homepage: http://www.fh-wedel.de/~si/HXmlToolbox/index.html"
      , "copyright: Copyright (c) 2005 Uwe Schmidt"
      ]

part3a
    = [ "tested-with: ghc-6.8"
      , "exposed: True"
      , "exposed-modules:"
      ]

part3b
    = [
      ]

modules
    = [ "  Control.Arrow.ArrowIf,"
      , "  Control.Arrow.ArrowIO,"
      , "  Control.Arrow.ArrowList,"
      , "  Control.Arrow.ArrowState,"
      , "  Control.Arrow.ArrowStrict,"
      , "  Control.Arrow.ArrowTree,"
      , "  Control.Arrow.IOListArrow,"
      , "  Control.Arrow.IOStateListArrow,"
      , "  Control.Arrow.ListArrow,"
      , "  Control.Arrow.ListArrows,"
      , "  Control.Arrow.StateListArrow,"
      , "  Control.Monad.MonadStateIO,"
      , "  Control.Strategies.DeepSeq,"
      , "  Data.AssocList,"
      , "  Data.Char.UTF8,"
      , "  Data.NavTree,"
      , "  Data.Tree.Class,"
      , "  Data.Tree.NTree.Filter,"
      , "  Data.Tree.NTree.TypeDefs,"
      , "  System.PipeOpen,"
      , "  Text.XML.HXT.Arrow,"
      , "  Text.XML.HXT.Arrow.DocumentInput,"
      , "  Text.XML.HXT.Arrow.DocumentOutput,"
      , "  Text.XML.HXT.Arrow.DOMInterface,"
      , "  Text.XML.HXT.Arrow.DTDProcessing,"
      , "  Text.XML.HXT.Arrow.Edit,"
      , "  Text.XML.HXT.Arrow.GeneralEntitySubstitution,"
      , "  Text.XML.HXT.Arrow.Namespace,"
      , "  Text.XML.HXT.Arrow.ParserInterface"
      , "  Text.XML.HXT.Arrow.Pickle,"
      , "  Text.XML.HXT.Arrow.Pickle.DTD,"
      , "  Text.XML.HXT.Arrow.Pickle.Schema,"
      , "  Text.XML.HXT.Arrow.Pickle.Xml,"
      , "  Text.XML.HXT.Arrow.ProcessDocument,"
      , "  Text.XML.HXT.Arrow.ReadDocument,"
      , "  Text.XML.HXT.Arrow.WriteDocument,"
      , "  Text.XML.HXT.Arrow.XmlArrow,"
      , "  Text.XML.HXT.Arrow.XmlIOStateArrow,"
      , "  Text.XML.HXT.Arrow.XmlNode,"
      , "  Text.XML.HXT.Arrow.XmlNodeSet,"
      , "  Text.XML.HXT.DOM,"
      , "  Text.XML.HXT.DOM.EditFilters,"
      , "  Text.XML.HXT.DOM.FormatXmlTree,"
      , "  Text.XML.HXT.DOM.IsoLatinTables,"
      , "  Text.XML.HXT.DOM.Namespace,"
      , "  Text.XML.HXT.DOM.NamespaceFilter,"
      , "  Text.XML.HXT.DOM.NamespacePredicates,"
      , "  Text.XML.HXT.DOM.TypeDefs,"
      , "  Text.XML.HXT.DOM.Unicode,"
      , "  Text.XML.HXT.DOM.UTF8Decoding,"
      , "  Text.XML.HXT.DOM.Util,"
      , "  Text.XML.HXT.DOM.XmlKeywords,"
      , "  Text.XML.HXT.DOM.XmlOptions,"
      , "  Text.XML.HXT.DOM.XmlState,"
      , "  Text.XML.HXT.DOM.XmlTree,"
      , "  Text.XML.HXT.DOM.XmlTreeFilter,"
      , "  Text.XML.HXT.DOM.XmlTreeFunctions,"
      , "  Text.XML.HXT.DOM.XmlTreeTypes,"
      , "  Text.XML.HXT.IO.GetFILE,"
      , "  Text.XML.HXT.IO.GetHTTPCurl,"
      , "  Text.XML.HXT.IO.GetHTTPNative,"
      , "  Text.XML.HXT.Parser,"
      , "  Text.XML.HXT.Parser.DefaultURI,"
      , "  Text.XML.HXT.Parser.DTDProcessing,"
      , "  Text.XML.HXT.Parser.HtmlParsec,"
      , "  Text.XML.HXT.Parser.HtmlParser,"
      , "  Text.XML.HXT.Parser.MainFunctions,"
      , "  Text.XML.HXT.Parser.ProtocolHandler,"
      , "  Text.XML.HXT.Parser.ProtocolHandlerFile,"
      , "  Text.XML.HXT.Parser.ProtocolHandlerHttpCurl,"
      , "  Text.XML.HXT.Parser.ProtocolHandlerHttpNative,"
      , "  Text.XML.HXT.Parser.ProtocolHandlerHttpNativeOrCurl,"
      , "  Text.XML.HXT.Parser.ProtocolHandlerUtil,"
      , "  Text.XML.HXT.Parser.XhtmlEntities,"
      , "  Text.XML.HXT.Parser.XmlEntities,"
      , "  Text.XML.HXT.Parser.XmlCharParser,"
      , "  Text.XML.HXT.Parser.XmlDTDParser,"
      , "  Text.XML.HXT.Parser.XmlDTDTokenParser,"
      , "  Text.XML.HXT.Parser.XmlInput,"
      , "  Text.XML.HXT.Parser.XmlOutput,"
      , "  Text.XML.HXT.Parser.XmlParsec,"
      , "  Text.XML.HXT.Parser.XmlParser,"
      , "  Text.XML.HXT.Parser.XmlTokenParser,"
      , "  Text.XML.HXT.Validator.AttributeValueValidation,"
      , "  Text.XML.HXT.Validator.DocTransformation,"
      , "  Text.XML.HXT.Validator.DocValidation,"
      , "  Text.XML.HXT.Validator.DTDValidation,"
      , "  Text.XML.HXT.Validator.IdValidation,"
      , "  Text.XML.HXT.Validator.RE,"
      , "  Text.XML.HXT.Validator.Validation,"
      , "  Text.XML.HXT.Validator.ValidationFilter,"
      , "  Text.XML.HXT.Validator.XmlRE,"
      , "  Text.XML.HXT.XPath,"
      , "  Text.XML.HXT.XPath.NavTree,"
      , "  Text.XML.HXT.XPath.XPathArithmetic,"
      , "  Text.XML.HXT.XPath.XPathDataTypes,"
      , "  Text.XML.HXT.XPath.XPathEval,"
      , "  Text.XML.HXT.XPath.XPathFct,"
      , "  Text.XML.HXT.XPath.XPathKeywords,"
      , "  Text.XML.HXT.XPath.XPathParser,"
      , "  Text.XML.HXT.XPath.XPathToNodeSet,"
      , "  Text.XML.HXT.XPath.XPathToString,"
      , "  Text.XML.HXT.XSLT.Application,"
      , "  Text.XML.HXT.XSLT.Common,"
      , "  Text.XML.HXT.XSLT.Compilation,"
      , "  Text.XML.HXT.XSLT.CompiledStylesheet,"
      , "  Text.XML.HXT.XSLT.Names,"
      , "  Text.XML.HXT.XSLT.XsltArrows,"
      , "  Text.XML.HXT.RelaxNG,"
      , "  Text.XML.HXT.RelaxNG.BasicArrows,"
      , "  Text.XML.HXT.RelaxNG.CreatePattern,"
      , "  Text.XML.HXT.RelaxNG.DataTypeLibMysql,"
      , "  Text.XML.HXT.RelaxNG.DataTypeLibraries,"
      , "  Text.XML.HXT.RelaxNG.DataTypeLibUtils,"
      , "  Text.XML.HXT.RelaxNG.DataTypes,"
      , "  Text.XML.HXT.RelaxNG.PatternFunctions,"
      , "  Text.XML.HXT.RelaxNG.PatternToString,"
      , "  Text.XML.HXT.RelaxNG.SchemaGrammar,"
      , "  Text.XML.HXT.RelaxNG.Schema,"
      , "  Text.XML.HXT.RelaxNG.Simplification,"
      , "  Text.XML.HXT.RelaxNG.Utils,"
      , "  Text.XML.HXT.RelaxNG.Validation,"
      , "  Text.XML.HXT.RelaxNG.Validator,"
      , "  Text.XML.HXT.RelaxNG.Unicode.Blocks,"
      , "  Text.XML.HXT.RelaxNG.Unicode.CharProps,"
      , "  Text.XML.HXT.RelaxNG.XmlSchema.DataTypeLibW3C,"
      , "  Text.XML.HXT.RelaxNG.XmlSchema.Regex,"
      , "  Text.XML.HXT.RelaxNG.XmlSchema.RegexParser"
      ]

part4a
    = [ "hs-source-dirs: ."
      , "ghc-options: -Wall -O2 -fglasgow-exts"
      , "import-dirs: /usr/local/lib/hxt/imports"
      , "library-dirs: /usr/local/lib/hxt"
      , "hs-libraries: HShxt"
      , "depends: base, haskell98, parsec, HTTP, HUnit, network, containers, directory, process"
      ]

part4b
    = [
      ]

main	:: IO()
main
    = do
      vers : cabal : modules <- getArgs
      putStrLn (cabalFile vers cabal modules)

cabalFile	:: String -> String -> [String] -> String
cabalFile vers cabal modules
    = unlines $
      part1 ++
      [ version ++ vers ] ++
      part2 ++
      ( if isCabal
	then part3b
	else part3a
      ) ++
      [ml modules] ++
      ( if isCabal
	then part4b
	else part4a
      )
    where
    isCabal = cabal == "cabal"
    ml = foldr1 (\ x y -> x ++ ",\n" ++ y) . map editPath
    editPath = ("  " ++) . map slash2dot . reverse . drop 1 . dropWhile (/= '.') . reverse
    slash2dot '/' = '.'
    slash2dot c   = c