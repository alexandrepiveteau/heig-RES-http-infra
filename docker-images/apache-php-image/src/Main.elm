module Main exposing (main)

import Api
import Browser
import Html exposing (Html)
import Html.Attributes as Attribute
import Http
import Time



-- MODEL


type alias Model =
    List Api.Transaction


init : () -> ( Model, Cmd Message )
init =
    always ( [], Cmd.none )



-- MESSAGES


type Message
    = GotTransactions (List Api.Transaction)
    | GotError
    | RequestTransactions


update : Message -> Model -> ( Model, Cmd Message )
update message existing =
    case message of
        GotTransactions transactions ->
            ( transactions, Cmd.none )

        GotError ->
            ( [], Cmd.none )

        RequestTransactions ->
            ( existing, Cmd.map resultToMessage Api.request )


resultToMessage : Result Http.Error (List Api.Transaction) -> Message
resultToMessage result =
    case result of
        Ok list ->
            GotTransactions list

        Err _ ->
            GotError


subscriptions : Model -> Sub Message
subscriptions _ =
    Time.every (5 * 1000) (always RequestTransactions)



-- VIEW


view : Model -> Html Message
view model =
    Html.div [ Attribute.class "container cards" ]
        (cards <| List.length model)


cards : Int -> List (Html Message)
cards count =
    List.repeat count <|
        Html.div [ Attribute.class "card" ]
            [ Html.div [ Attribute.class "skill-level" ]
                [ Html.span [] [ Html.text "+" ]
                , Html.h2 [] [ Html.text <| String.fromInt count ]
                ]
            , Html.div [ Attribute.class "skill-meta" ]
                [ Html.h3 [] [ Html.text "Projects" ]
                , Html.span [] [ Html.text "Adapting and creating solutions for customer's needs" ]
                ]
            ]



-- APPLICATION


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
