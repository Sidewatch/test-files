{-# LANGUAGE LambdaCase #-}
-- Haskell: a typed order pipeline with a Maybe-returning parser.
module Sample (Order (..), parseOrder, revenue, main) where

import Data.List (sortOn)
import qualified Data.Map.Strict as Map
import Text.Read (readMaybe)

data Status = Pending | Paid | Cancelled String deriving (Show, Eq)

data Order = Order
  { number :: Int
  , total  :: Double
  , status :: Status
  } deriving (Show)

parseOrder :: String -> Maybe Order
parseOrder line = case words line of
  [n, t, "paid"]    -> Order <$> readMaybe n <*> readMaybe t <*> pure Paid
  [n, t, "pending"] -> Order <$> readMaybe n <*> readMaybe t <*> pure Pending
  _                 -> Nothing

revenue :: [Order] -> Double
revenue = sum . map total . filter ((== Paid) . status)

main :: IO ()
main = do
  let orders = [o | Just o <- map parseOrder ["1 120.5 paid", "2 42 pending", "x y z"]]
      byStatus = Map.fromListWith (+) [(show (status o), 1 :: Int) | o <- orders]
  mapM_ print (sortOn number orders)
  putStrLn $ "revenue: " ++ show (revenue orders) ++ " " ++ show byStatus
