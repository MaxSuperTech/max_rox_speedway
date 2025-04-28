function ShowCountdownText(text, duration)
    local scaleform = RequestScaleformMovie("COUNTDOWN")
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end

    BeginScaleformMovieMethod(scaleform, "SET_MESSAGE")
    PushScaleformMovieMethodParameterString(text)
    PushScaleformMovieMethodParameterString("") -- sous-texte vide
    EndScaleformMovieMethod()

    local timer = GetGameTimer() + duration
    while GetGameTimer() < timer do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        Wait(0)
    end
end