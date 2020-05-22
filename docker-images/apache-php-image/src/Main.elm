module Main exposing (main)

import Api
import Browser
import Html exposing (Html)
import Html.Attributes as Attribute
import Http
import Task
import Time



-- MODEL


type alias Model =
    List Api.Transaction


init : () -> ( Model, Cmd Message )
init =
    always ( [], Task.succeed RequestTransactions |> Task.perform identity )



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
        (List.map card model)


card : Api.Transaction -> Html Message
card transaction =
    Html.div [ Attribute.class "card" ]
        [ Html.div [ Attribute.class "skill-level" ]
            [ Html.span [] [ Html.text "we like" ]
            , Html.h2 [] [ Html.text "Elm" ]
            ]
        , Html.div [ Attribute.class "skill-meta" ]
            [ Html.h3 [] [ Html.text transaction.title ]
            , Html.span []
                [ Html.text <| "Amount is " ++ String.fromFloat transaction.amount ]
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
