module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attribute
import Time



-- MODEL


type alias Model =
    Int


init : () -> ( Model, Cmd Message )
init =
    always ( 0, Cmd.none )



-- MESSAGES


type Message
    = Increment


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        Increment ->
            ( model + 1, Cmd.none )


subscriptions : Model -> Sub Message
subscriptions _ =
    Time.every (5 * 1000) (always Increment)



-- VIEW


view : Model -> Html Message
view model =
    Html.div [ Attribute.class "container cards" ]
        (cards model)


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
