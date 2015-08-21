{-# LANGUAGE ForeignFunctionInterface, ScopedTypeVariables, JavaScriptFFI, QuasiQuotes, Rank2Types #-}

module Main where
import Control.Concurrent
import Control.Exception
import Control.Monad

import Zepto.Types
import Zepto.Primitives
import Zepto.Variables

import GHCJS.Foreign.QQ

-- |Prints the usage
printUsage :: IO ()
printUsage = do printVersion
                putStrLn("\nUsage: " ++
                         "\n\twithout arguments - runs REPL" ++
                         "\n\t-h/--help         - display this help message" ++
                         "\n\t-S/--silent       - runs REPL without displaying header" ++
                         "\n\t-s/--single       - runs single statement passed in as string" ++
                         "\n\t<some zepto file> - run file" ++
                         "\n\nMore information can be found on " ++
                         "http://zepto.veitheller.de")

-- |Prints the version
printVersion :: IO ()
printVersion = putStrLn ("zepto Version "
                        ++ versionStr
                        ++ "(zepto-js 0.2.0), "
                        ++ "compiled with GHC version "
                        ++ show (__GLASGOW_HASKELL__::Integer))

-- |Prints the copyright notice
printCopyright :: IO ()
printCopyright = putStrLn("Copyright (C) 2015 Veit Heller (GPL)\n" ++
                          "This is free software; " ++
                          "see the accompanying LICENSE " ++
                          "for copying conditions.\n" ++
                          "There is NO warranty whatsoever.\n" ++
                          "Hail Eris, all rites reversed.\n")

-- |makes a new empty environment
primitiveBindings :: IO Env
primitiveBindings = nullEnv >>= flip extendEnv (fmap (makeFunc IOFunc) ioPrimitives ++
                                fmap (makeFunc PrimitiveFunc) primitives ++
                                fmap (makeFunc EvalFunc) evalPrimitives)
    where makeFunc constructor (var, func, _) = ((vnamespace, var), constructor func)

-- |Parses arguments and runs the REPL
main :: IO ()
main = do
          [js_| zeptoInit(); |]
          printVersion
          printCopyright
          [js_| console.log('Compiling stdlib...'); |]
          stdSrc <- [js| zepto.getStdlib() |]
          env <- primitiveBindings
          putStrLn =<< evaluation env stdSrc
          [js_| console.log('stdlib compiled!'); zepto.enableEditor(); |]
          forever $ do
            [jsi_| zepto.waitForChange($c); |]
            threadDelay 500000
            a <- [js| zepto.getEditorContents() |]
            x <- evaluation env a
            [js_| zepto.write(`x); |]
    where
      evaluation env x = catch (evalStrings env x) handler
      handler msg@(SomeException _) = return $ "Caught error: " ++ show (msg::SomeException)
