module Main exposing (main)

import Api
import Browser
import Html exposing (Html)
import Html.Events as Event
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
    | RequestNew Api.ContainerType
    | RequestKill String


update : Message -> Model -> ( Model, Cmd Message )
update message existing =
    case message of
        GotContainers containers ->
            ( containers, Cmd.none )

        RequestContainers ->
            ( existing, Cmd.map GotContainers Api.get )

        RequestNew type_ ->
            ( existing, Api.create RequestContainers type_ )

        RequestKill identifier ->
            ( existing, Api.delete RequestContainers identifier )


subscriptions : Model -> Sub Message
subscriptions _ =
    Time.every (5 * 1000) (always RequestContainers)



-- VIEW


view : Model -> Html Message
view model =
    Html.div []
        [ Html.div [] (List.map card model)
        , Html.button [ Event.onClick <| RequestNew Api.Static ] [ Html.text "New static" ]
        , Html.button [ Event.onClick <| RequestNew Api.Dynamic ] [ Html.text "New dynamic" ]
        ]


card : Api.Container -> Html Message
card container =
    let
        typeToString : Api.ContainerType -> String
        typeToString type_ =
            case type_ of
                Api.Static ->
                    "STATIC : "

                Api.Dynamic ->
                    "DYNAMIC : "
    in
    Html.div []
        [ Html.em [] [ Html.text <| typeToString container.type_ ]
        , Html.text container.name
        , Html.button [ Event.onClick <| RequestKill container.name ] [ Html.text "Kill" ]
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
