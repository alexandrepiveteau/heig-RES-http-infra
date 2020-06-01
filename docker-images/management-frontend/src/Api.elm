module Api exposing
    ( Container
    , ContainerType(..)
    , create
    , delete
    , get
    )

import Http
import Json.Decode


type ContainerType
    = Static
    | Dynamic


type alias Container =
    { name : String
    , type_ : ContainerType
    }


containerTypeDecoder : Json.Decode.Decoder ContainerType
containerTypeDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\text ->
                case text of
                    "static" ->
                        Json.Decode.succeed Static

                    "dynamic" ->
                        Json.Decode.succeed Dynamic

                    _ ->
                        Json.Decode.fail <| "Unknown container type " ++ text
            )


encodeContainerType : ContainerType -> String
encodeContainerType type_ =
    case type_ of
        Static ->
            "static"

        Dynamic ->
            "dynamic"


containerDecoder : Json.Decode.Decoder Container
containerDecoder =
    Json.Decode.map2
        Container
        (Json.Decode.field "identifier" <| Json.Decode.string)
        (Json.Decode.field "type" <| containerTypeDecoder)


get : Cmd (List Container)
get =
    Http.get
        { url = "/management/api/all"
        , expect =
            Http.expectJson (Result.withDefault []) <|
                Json.Decode.list containerDecoder
        }


delete : msg -> String -> Cmd msg
delete result name =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "/management/api/delete/" ++ name
        , body = Http.emptyBody
        , expect =
            Http.expectWhatever
                (Result.map (always result)
                    >> Result.withDefault result
                )
        , timeout = Nothing
        , tracker = Nothing
        }


create : msg -> ContainerType -> Cmd msg
create result type_ =
    Http.post
        { url = "/management/" ++ encodeContainerType type_
        , body = Http.emptyBody
        , expect =
            Http.expectWhatever
                (Result.map (always result)
                    >> Result.withDefault result
                )
        }
