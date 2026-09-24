-- PureScript: a typed order model with a Maybe-returning parser and a fold.
module Sample where

import Prelude

import Data.Array (filter, mapMaybe)
import Data.Foldable (sum)
import Data.Int (fromString)
import Data.Maybe (Maybe(..))
import Data.Number as Number
import Data.String (split, Pattern(..))
import Effect (Effect)
import Effect.Console (log)

data Status = Pending | Paid | Cancelled String

derive instance eqStatus :: Eq Status

type Order = { number :: Int, total :: Number, status :: Status }

parseOrder :: String -> Maybe Order
parseOrder line = case split (Pattern ",") line of
  [n, t, "paid"] -> { number: _, total: _, status: Paid } <$> fromString n <*> Number.fromString t
  [n, t, "pending"] -> { number: _, total: _, status: Pending } <$> fromString n <*> Number.fromString t
  _ -> Nothing

revenue :: Array Order -> Number
revenue = sum <<< map _.total <<< filter (\o -> o.status == Paid)

main :: Effect Unit
main = do
  let orders = mapMaybe parseOrder [ "1,120.5,paid", "2,42,pending", "x,y,z" ]
  log $ "revenue: " <> show (revenue orders)
