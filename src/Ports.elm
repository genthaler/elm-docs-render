port module Ports exposing (Response(..), echoRequest, exit, fileReadRequest, fileWriteRequest, response, shellRequest)

import Json.Decode as D
import Json.Decode.Extra as JDE
import Json.Encode as E
import Result.Extra



-- Request


port request : E.Value -> Cmd msg


fileReadRequest : String -> Cmd msg
fileReadRequest path =
    request <|
        E.object
            [ ( "command", E.string "FileRead" )
            , ( "path", E.string path )
            ]


fileWriteRequest : ( String, String ) -> Cmd msg
fileWriteRequest ( path, content ) =
    request <|
        E.object
            [ ( "command", E.string "FileWrite" )
            , ( "path", E.string path )
            , ( "content", E.string content )
            ]


echoRequest : String -> Cmd msg
echoRequest message =
    request <|
        E.object
            [ ( "command", E.string "Echo" )
            , ( "message", E.string message )
            ]


shellRequest : String -> Cmd msg
shellRequest cmd =
    request <|
        E.object
            [ ( "command", E.string "Shell" )
            , ( "cmd", E.string cmd )
            ]


exit : Int -> String -> Cmd msg
exit exitCode message =
    request <|
        E.object
            [ ( "command", E.string "Exit" )
            , ( "exitCode", E.int exitCode )
            , ( "message", E.string message )
            ]



-- Response


type Response
    = NoOp
    | Stdout String
    | Stderr String


port rawResponse : (D.Value -> msg) -> Sub msg


response : Sub Response
response =
    Sub.map (D.decodeValue decoder >> Result.mapError (Stderr << D.errorToString) >> Result.Extra.merge) (rawResponse identity)


decoder : D.Decoder Response
decoder =
    D.oneOf
        [ D.field "code" D.int
            |> D.andThen
                (\i ->
                    if i == 0 then
                        D.fail "never mind, move along"

                    else
                        D.map Stderr <| JDE.withDefault "No stderr available" <| D.field "stderr" D.string
                )
        , D.map Stdout (D.field "stdout" D.string)
        , D.map Stderr (D.succeed "could not match response")
        ]
