module Main exposing (main)

import Api
import Browser
import Html exposing (Html)
import Task
import Time



-- MODEL


type alias Model =
    List Api.Container


init : () -> ( Model, Cmd Message )
init =
    always ( [], Task.succeed RequestContainers |> Task.perform identity )



-- MESSAGES


type Message
    = GotContainers (List Api.Container)
    | RequestContainers


update : Message -> Model -> ( Model, Cmd Message )
update message existing =
    case message of
        GotContainers containers ->
            ( containers, Cmd.none )

        RequestContainers ->
            ( existing, Cmd.map GotContainers Api.get )


subscriptions : Model -> Sub Message
subscriptions _ =
    Time.every (5 * 1000) (always RequestContainers)



-- VIEW


view : Model -> Html Message
view model =
    Html.div []
        (List.map card model)


card : Api.Container -> Html Message
card container =
    Html.div []
        [ Html.div []
            [ Html.span [] [ Html.text "we like" ]
            , Html.h2 [] [ Html.text "Elm" ]
            ]
        , Html.div []
            [ Html.h3 [] [ Html.text container.name ]
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
