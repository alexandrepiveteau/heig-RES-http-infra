module Api exposing
    ( Transaction
    , request
    )

import Http
import Json.Decode


type alias Transaction =
    { amount : Float
    , title : String
    }


{-| Helps decode a Json.Decode.Value into a Transaction record.
-}
decoder : Json.Decode.Decoder Transaction
decoder =
    Json.Decode.map2 Transaction
        (Json.Decode.field "amount" Json.Decode.float)
        (Json.Decode.field "title" Json.Decode.string)


{-| Requests a List Transaction from the api server.
-}
request : Cmd (Result Http.Error (List Transaction))
request =
    Http.get
        { url = "/api/transactions/"
        , expect =
            Http.expectJson identity <|
                Json.Decode.list decoder
        }
