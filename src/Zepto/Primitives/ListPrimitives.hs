module Zepto.Primitives.ListPrimitives where
import Data.Array (elems, listArray, (!))
import Data.List (findIndex)
import Control.Monad.Except

import Zepto.Types

car :: [LispVal] -> ThrowsError LispVal
car [List (x : _)] = return x
car [DottedList (x : _) _] = return x
car [badArg] = throwError $ TypeMismatch "pair" badArg
car badArgList = throwError $ NumArgs 1 badArgList

cdr :: [LispVal] -> ThrowsError LispVal
cdr [List (_ : xs)] = return $ List xs
cdr [DottedList [_] x] = return $ x
cdr [DottedList (_ : xs) x] = return $ DottedList xs x
cdr [badArg] = throwError $ TypeMismatch "pair" badArg
cdr badArgList = throwError $ NumArgs 1 badArgList

cons :: [LispVal] -> ThrowsError LispVal
cons [x, List []] = return $ List [x]
cons [x, List xs] = return $ List $ x : xs
cons [x, DottedList xs xlast] = return $ DottedList (x : xs) xlast
cons [x, y] = return $ DottedList [x] y
cons badArgList = throwError $ NumArgs 2 badArgList

makeVector, buildVector, vectorLength, vectorRef, vectorToList, listToVector, stringRef, stringFind :: [LispVal] -> ThrowsError LispVal
makeVector [n@(SimpleVal (Number _))] = makeVector [n, List []]
makeVector [SimpleVal (Number (NumI n)), a] = do
    let l = replicate (fromInteger n) a
    return $ Vector $ listArray (0, length l - 1) l
makeVector [SimpleVal (Number (NumS n)), a] = do
    let l = replicate n a
    return $ Vector $ listArray (0, length l - 1) l
makeVector [badType] = throwError $ TypeMismatch "integer" badType
makeVector badArgList = throwError $ NumArgs 1 badArgList

buildVector (o:os) = do
    let l = o:os
    return $ Vector $ listArray (0, length l - 1) l
buildVector badArgList = throwError $ NumArgs 1 badArgList

vectorLength [Vector v] = return $ fromSimple $ Number $ NumI $ toInteger $ length (elems v)
vectorLength [badType] = throwError $ TypeMismatch "vector" badType
vectorLength badArgList = throwError $ NumArgs 1 badArgList

vectorRef [Vector v, SimpleVal (Number (NumI n))] = return $ v ! fromInteger n
vectorRef [Vector v, SimpleVal (Number (NumS n))] = return $ v ! n
vectorRef [badType] = throwError $ TypeMismatch "vector integer" badType
vectorRef badArgList = throwError $ NumArgs 2 badArgList

vectorToList [Vector v] = return $ List $ elems v
vectorToList [badType] = throwError $ TypeMismatch "vector" badType
vectorToList badArgList = throwError $ NumArgs 1 badArgList

listToVector [List l] = return $ Vector $ listArray (0, length l - 1) l
listToVector [badType] = throwError $ TypeMismatch "list" badType
listToVector badArgList = throwError $ NumArgs 1 badArgList

buildString :: [LispVal] -> ThrowsError LispVal
buildString [List []] = return $ fromSimple $ String ""
buildString [SimpleVal (Character c)] = return $ fromSimple $ String [c]
buildString (SimpleVal (Character c) : rest) = do
    cs <- buildString rest
    case cs of
        SimpleVal (String s) -> return $ fromSimple $ String $ c : s
        badType -> throwError $ TypeMismatch "character" badType
buildString [badType] = throwError $ TypeMismatch "character" badType
buildString badArgList = throwError $ NumArgs 1 badArgList

makeString :: [LispVal] -> ThrowsError LispVal
makeString [SimpleVal (Number n)] = return $ fromSimple $ _makeString n ' ' ""
    where _makeString count ch s =
            if count == 0
                then String s
                else _makeString (count - 1) ch (s ++ [ch])
makeString badArgList = throwError $ NumArgs 1 badArgList

stringLength :: [LispVal] -> ThrowsError LispVal
stringLength [SimpleVal (String s)] = return $ fromSimple $ Number $ foldr (const (+1)) 0 s
stringLength [badType] = throwError $ TypeMismatch "string" badType
stringLength badArgList = throwError $ NumArgs 1 badArgList

stringRef [SimpleVal (String v), SimpleVal (Number (NumI n))] =
        if n >= 0
           then return $ fromSimple $ Character $ v !! fromInteger n
           else return $ fromSimple $ Character $ v !! ((length v) - fromInteger n)
stringRef [SimpleVal (String v), SimpleVal (Number (NumS n))] =
        if n >= 0
           then return $ fromSimple $ Character $ v !! n
           else return $ fromSimple $ Character $ v !! ((length v) - n)
stringRef [badType] = throwError $ TypeMismatch "string integer" badType
stringRef badArgList = throwError $ NumArgs 2 badArgList

stringFind [SimpleVal (String v), SimpleVal (Character x)] =
        case findIndex (\m -> x == m) v of
           Just n -> return $ SimpleVal $ Number $ NumI $ toInteger n
           _      -> return $ SimpleVal $ Number $ NumI $ -1
stringFind [badType, SimpleVal (Character _)] = throwError $ TypeMismatch "string" badType
stringFind [SimpleVal (String _), badType] = throwError $ TypeMismatch "character" badType
stringFind badArgList = throwError $ NumArgs 2 badArgList

substring :: [LispVal] -> ThrowsError LispVal
substring [SimpleVal (String s), SimpleVal (Number (NumI start)), SimpleVal (Number (NumI end))] = do
    let len = fromInteger $ end - start
    let begin = fromInteger start
    return $ fromSimple $ String $ (take len . drop begin) s
substring [SimpleVal (String s), SimpleVal (Number (NumS start)), SimpleVal (Number (NumS end))] = do
    let len = end - start
    return $ fromSimple $ String $ (take len . drop start) s
substring [badType] = throwError $ TypeMismatch "string integer integer" badType
substring badArgList = throwError $ NumArgs 3 badArgList

stringExtend :: [LispVal] -> ThrowsError LispVal
stringExtend v@(SimpleVal (String _) : _) = extend' v
  where extend' :: [LispVal] -> ThrowsError LispVal
        extend' [SimpleVal (Character s)] = return $ fromSimple $ String [s]
        extend' [SimpleVal (String s)] = return $ fromSimple $ String s
        extend' [s] = throwError $ TypeMismatch "string/character" s
        extend' (SimpleVal (String st) : sts) = do
          rest <- extend' sts
          case rest of
              SimpleVal (String s) -> return $ fromSimple $ String $ st ++ s
              SimpleVal (Character c) -> return $ fromSimple $ String $ st ++ [c]
              elsewise -> throwError $
                            TypeMismatch "string/character" elsewise
        extend' _ = throwError $ InternalError "this should not happen"
stringExtend [badType] = throwError $ NumArgs 2 [badType]
stringExtend (badType : _) = throwError $ TypeMismatch "string" badType
stringExtend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList

listAppend :: [LispVal] -> ThrowsError LispVal
listAppend (vec@(List _) : t) = append' [vec] t
  where append' :: [LispVal] -> [LispVal] -> ThrowsError LispVal
        append' [] [v] = return $ List [v]
        append' [List x] (st : sts) = do
          rest <- append' [] sts
          case rest of
              List s -> return $ List $ x ++ [st] ++ s
              elsewise -> throwError $ TypeMismatch "list/element" elsewise
        append' [] (st : sts) = do
          rest <- append' [] sts
          case rest of
              List s -> return $ List $ [st] ++ s
              elsewise -> throwError $ TypeMismatch "list/element" elsewise
        append' [] [] = return $ List []
        append' _ _ = throwError $ InternalError "This should not happen"
listAppend [badType] = throwError $ NumArgs 2 [badType]
listAppend (badType : _) = throwError $ TypeMismatch "list" badType
listAppend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList

vectorAppend :: [LispVal] -> ThrowsError LispVal
vectorAppend (vec@(Vector _) : t) = append' [vec] t
  where append' :: [LispVal] -> [LispVal] -> ThrowsError LispVal
        append' [] [x] = return $ Vector $ listArray (0, 0) [x]
        append' [Vector x] (st : sts) = do
          rest <- append' [] sts
          let ast = elems x
          case rest of
              Vector s ->
                  let z = st : elems s
                  in return $ Vector $
                              listArray (0, (length ast + length z) - 1) (ast ++ z)
              elsewise -> throwError $ TypeMismatch "vector/element" elsewise
        append' [] (st : sts) = do
          rest <- append' [] sts
          case rest of
              Vector s -> return $ Vector $
                          listArray (0, length (elems s)) (st : elems s)
              elsewise -> throwError $ TypeMismatch "vector/element" elsewise
        append' [] [] = return $ Vector $ listArray (0, -1) []
        append' _ _ = throwError $ InternalError "This should not happen"
vectorAppend [badType] = throwError $ NumArgs 2 [badType]
vectorAppend (badType : _) = throwError $ TypeMismatch "vector" badType
vectorAppend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList

allAppend :: [LispVal] -> ThrowsError LispVal
allAppend v@[SimpleVal (String _), _] = stringExtend v
allAppend v@(SimpleVal (String _) : _) = stringExtend v
allAppend v@[List _, _] = listAppend v
allAppend v@(List _ : _) = listAppend v
allAppend v@[Vector _, _] = vectorAppend v
allAppend v@(Vector _ : _) = vectorAppend v
allAppend [badType] = throwError $ NumArgs 2 [badType]
allAppend (badType : _) = throwError $ TypeMismatch "string/list/vector" badType
allAppend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList

listExtend :: [LispVal] -> ThrowsError LispVal
listExtend l@(List _ : _) = append' l
  where append' :: [LispVal] -> ThrowsError LispVal
        append' [List v] = return $ List v
        append' [v] = return $ List [v]
        append' [] = return $ List []
        append' (List st : sts) = do
          rest <- append' sts
          case rest of
              List s -> return $ List $ st ++ s
              elsewise -> throwError $ TypeMismatch "list/element" elsewise
        append' (st : sts) = do
          rest <- append' sts
          case rest of
              List s -> return $ List $ st : s
              elsewise -> throwError $ TypeMismatch "list/element" elsewise
listExtend [badType] = throwError $ NumArgs 2 [badType]
listExtend (badType : _) = throwError $ TypeMismatch "list" badType
listExtend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList

vectorExtend :: [LispVal] -> ThrowsError LispVal
vectorExtend v@(Vector _: _) = append' v
  where append' :: [LispVal] -> ThrowsError LispVal
        append' [Vector x] = return $ Vector x
        append' [x] = return $ Vector $ listArray (0, 0) [x]
        append' (Vector st : sts) = do
          rest <- append' sts
          case rest of
              Vector s -> return $ Vector $
                          listArray (0, length (elems s) + length (elems st) - 1)
                                    (elems st ++ elems s)
              elsewise -> throwError $ TypeMismatch "vector/element" elsewise
        append' (st : sts) = do
          rest <- append' sts
          case rest of
              Vector s -> return $ Vector $
                          listArray (0, length (elems s)) (st : elems s)
              elsewise -> throwError $ TypeMismatch "vector/element" elsewise
        append' _ = throwError $ InternalError "This should not happen"
vectorExtend [badType] = throwError $ NumArgs 2 [badType]
vectorExtend (badType : _) = throwError $ TypeMismatch "vector" badType
vectorExtend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList

allExtend :: [LispVal] -> ThrowsError LispVal
allExtend v@[SimpleVal (String _), _] = stringExtend v
allExtend v@(SimpleVal (String _) : _) = stringExtend v
allExtend v@[List _, _] = listExtend v
allExtend v@(List _ : _) = listExtend v
allExtend v@[Vector _, _] = vectorExtend v
allExtend v@(Vector _ : _) = vectorExtend v
allExtend [badType] = throwError $ NumArgs 2 [badType]
allExtend (badType : _) = throwError $ TypeMismatch "string/list/vector" badType
allExtend badArgList = throwError $ BadSpecialForms "Unable to process" badArgList
