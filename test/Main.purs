module Test.Main where

import Prelude

import Effect
import Data.FunctorWithIndex (mapWithIndex)
import Data.Foldable (maximumBy, product)
import Data.Function (on)
import Data.Int (pow)
import Data.Matrix (Matrix(..), column, fill, height, replicate', row, unsafeIndex, width, zipWithE)
import Data.Matrix.Reps (matrix11, matrix22, matrix33)
import Data.Matrix.Transformations (resize, transpose, mkPermutation)
import Data.Matrix.Operations ((⇥), (⤓), findMaxIndex)
import Data.Matrix.Algorithms (det, luDecomp, inverse)
import Data.Maybe (fromJust)
import Data.Rational (Rational, fromInt, (%), toNumber)
import Data.Tuple (Tuple(Tuple))
import Data.Tuple as Tuple
import Data.Typelevel.Num (D3, D2, d0, d1, D5)
import Data.Vec (vec2, (+>))
import Data.Vec as Vec
import Test.QuickCheck (Result, (===), (<?>))
import Test.Unit (suite, test)
import Test.Unit.Assert (equal)
import Test.Unit.Main (runTest)
import Test.Unit.QuickCheck (quickCheck)
import Partial.Unsafe (unsafePartial)

a1 :: Matrix D3 D3 Number
a1 = matrix33
    1.0 4.0 (-1.0)
    3.0 0.0 5.0
    2.0 2.0 1.0

a2 :: Matrix D3 D3 Rational
a2 = map fromInt $ matrix33
    1 4 (-1)
    3 (-12) 8
    2 (-6) 3


a3 :: Matrix D3 D3 Number
a3 = matrix33
    0.0 4.0 (-1.0)
    1.0 2.0 1.0
    2.0 1.0 5.0

a4 :: Matrix D3 D3 Rational
a4 = map fromInt $ matrix33
    1 4 5
    1 6 11
    2 6 7

a5 ∷ Matrix D3 D3 Number
a5 = matrix33
  2.0 0.0 0.0
  0.0 3.0 0.0
  0.0 0.0 4.0

main ::
  Effect
    Unit
main = runTest do

  suite "Data.Matrix" do
    let
      a = matrix33 1.0 4.0 (-1.0) 3.0 0.0 5.0 2.0 2.0 1.0
      p = matrix33 0 0 0 1 0 0 0 1 0

    test "mkPermutation" do
      equal p (mkPermutation (_ + 1))
    -- test "lrSplit quickCheck" do
      -- quickCheck identityProp -- needs Arbituary implementation
    test "luDecomp 3" do
      let
        {l, u, p} = luDecomp a3
      equal (p*a3) (l*u)
    test "luDecomp 2" do
      let
        {l, u, p} = luDecomp a2
      equal (p * a2) (l * u)
    test "luDecomp 3" do
      let
        m = map fromInt $ matrix33 1 4 (-1) 3 0 5 2 2 1

        {l, u, p} = luDecomp m

        exp'l = matrix33 (1 % 1) (0 % 1) (0 % 1) (1 % 3) (1 % 1) (0 % 1) (2 % 3) (1 % 2) (1 % 1)
        exp'u = matrix33 (3 % 1) (0 % 1) (5 % 1) (0 % 1) (4 % 1) (- 8 % 3) (0 % 1) (0 % 1) (- 1 % 1)
        exp'p = transpose $  matrix33 (0 % 1) (1 % 1) (0 % 1) (1 % 1) (0 % 1) (0 % 1) (0 % 1) (0 % 1) (1 % 1)
      equal exp'l l
      equal exp'u u
      equal exp'p p
    test "luDecomp 4" do
      let
        m = map fromInt $ matrix33 1 8 (-1) 3 21 5 2 (-6) 1

        {l, u, p} = luDecomp m
        exp'p = map fromInt $ matrix33 0 1 0 0 0 1 1 0 0
        exp'l = matrix33 one zero zero (2 % 3) one zero (1 % 3) (-5 % 100) one

      -- logShow l
      -- logShow u
      -- logShow p
      equal (p*m) (l*u)
      equal exp'l l
    suite "determinant" do
      test "det1" do
        let
          m = map fromInt $ matrix33 1 4 (-1) 3 0 5 2 2 1
        equal (fromInt 12) (det m)
      test "det2" do
        let
          m2 = map fromInt $ matrix33 1 8 (-1) 3 21 5 2 (-6) 1
        equal (fromInt 167) (det m2)
      test "determinant is invariant to transpose" do
        quickCheck $ \(m :: Matrix D5 D5 Int) ->
          det m === det (transpose m)
      test "determinant of triangle matrix is product of diagonal" do
        quickCheck $ \(x11 :: Int) x12 x13 x22 x23 x33 ->
          let 
            m = matrix33 
                x11 x12 x13 
                0   x22 x23 
                0   0   x33
          in
            det m === product [x11, x22, x33]
      test "determinant of 1x1 Matrix is its value" do
        quickCheck $ \(x11:: Int) ->
          det (matrix11 x11) === x11
    test "consRowVec" do
      let
        b = matrix22 1 2 3 4
        m2 = vec2 7 8 ⤓ b
      equal 3 $ height m2
      equal 2 $ width m2

      equal 7 $ unsafePartial $ unsafeIndex m2 0 0
      equal 8 $ unsafePartial $ unsafeIndex m2 1 0
      equal 1 $ unsafePartial $ unsafeIndex m2 0 1
      equal 2 $ unsafePartial $ unsafeIndex m2 1 1
      equal 3 $ unsafePartial $ unsafeIndex m2 0 2
      equal 4 $ unsafePartial $ unsafeIndex m2 1 2

    test "consColVec" do
      let
        b = matrix22 1 2 3 4
        m2 = vec2 7 8 ⇥ b
      equal 2 $ height m2
      equal 3 $ width m2

      equal 7 $ unsafePartial $ unsafeIndex m2 0 0
      equal 1 $ unsafePartial $ unsafeIndex m2 1 0
      equal 2 $ unsafePartial $ unsafeIndex m2 2 0
      equal 8 $ unsafePartial $ unsafeIndex m2 0 1
      equal 3 $ unsafePartial $ unsafeIndex m2 1 1
      equal 4 $ unsafePartial $ unsafeIndex m2 2 1

    test "fill" do
      let
        m = fill (\x y → (1+x)*(1+y))
        m' = matrix33 1 2 3 2 4 6 3 6 9
      equal m m'

    test "replicate'" do
      let
        m = replicate' "hi"
        m' = matrix22 "hi" "hi" "hi" "hi"
      equal m' m

    test "zipWithE" do
      let
        m = matrix22 "hi" "hello" "foo" "bar"
        n = matrix22 "there" "asd" "bsd" "asd"
        u = matrix22 "hithere" "helloasd" "foobsd" "barasd"
      equal u $ zipWithE (<>) m n

    test "map" do
      let
        m = matrix22 1 2 3 4
        n = matrix22 1 4 9 16
      equal n $ map (_ `pow` 2) m

    test "add" do
      let
        m = matrix22 1 2 3 4
        n = matrix22 5 6 7 8
        r = matrix22 6 8 10 12
      equal r $ m + n

    test "negate" do
      let
        m = matrix22 1 2 3 4
        r = matrix22 (-1) (-2) (-3) (-4)
      equal m $ negate r

    test "column" do
      let
        m = matrix22 5 3 0 6
        r = vec2 5 0
        r' = vec2 3 6
      equal r $ column m d0
      equal r' $ column m d1

    test "row" do
      let
        m = matrix22 5 3 0 6
        r = vec2 5 3
        r' = vec2 0 6
      equal r $ row m d0
      equal r' $ row m d1

    test "mul" do
      let
        m = matrix33 1 2 3 4 5 6 7 8 9
        n = matrix33 1 0 0 2 3 0 3 0 0
        r = matrix33 14 6 0 32 15 0 50 24 0
        r' = matrix33 1 2 3 14 19 24 3 6 9
      equal m $ one * m
      equal n $ one * n
      equal zero $ zero * m
      equal zero $ zero * n
      equal r $ m * n
      equal r' $ n * m

    test "transpose" do
      let
        m = matrix22 1 2 3 4
        m' = matrix22 1 3 2 4
      equal m' $ transpose m
    test "resize" do
      let
        a = matrix33 1.0 4.0 (-1.0) 3.0 0.0 5.0 2.0 2.0 1.0
        sa = resize a
        sa' = matrix22 1.0 4.0 3.0 0.0
      equal sa' sa

    test "findMaxIndex" do
      quickCheck \(x :: Int) ->
        (findMaxIndex (x +> Vec.empty)) === 0 
      quickCheck \(x1 :: Int) x2 x3 ->
        let
          actual = findMaxIndex (x1 +> x2 +> x3 +> Vec.empty)
          expected =
            unsafePartial
              ( [x1, x2, x3]
                  # mapWithIndex Tuple
                  # maximumBy (compare `on` Tuple.snd)
                  # fromJust
                  # Tuple.fst 
              )
        in
          actual === expected 