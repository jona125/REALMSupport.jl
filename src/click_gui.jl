using Observables
using GtkObservables
using GtkObservables.Gtk4: GtkEventControllerKey, signal_connect
using ImageView
using ImageView: RGB

"""
    record_points(pointfile, img; overwrite=false)

Display `img` in a window and allow the user to mark points in the image by pressing 'm' while hovering
the mouse over desired point. The points are recorded in `pointfile` as a CSV file with columns `x, y, z`.

Press 'q' to quit (the window will close).
"""
function record_points(pointfile::AbstractString, img; overwrite::Bool = false)
    dct = imshow(img)
    win = dct["gui"]["window"]
    canvas = dct["gui"]["canvas"]
    sd = dct["roi"]["slicedata"]
    mouse = canvas.mouse.motion
    eck = GtkEventControllerKey(win)
    cmd = Observable{Char}(' ')
    signal_connect(eck, "key-pressed") do controller, keyval, keycode, state
        cmd[] = keyval
    end
    overwrite && rm(pointfile; force = true)
    on(cmd) do c
        if c == 'm'
            xymouse, z = mouse[].position, sd.signals[1][]
            xy = round.(Int, float.((xymouse.x, xymouse.y)))
            open(pointfile, "a") do f
                println(f, "$(xy[1]), $(xy[2]), $z")
            end
            annotate!(
                dct,
                AnnotationPoint(
                    xy[1],
                    xy[2];
                    z,
                    shape = '.',
                    size = 4,
                    color = RGB(1, 0, 0),
                ),
            )
        elseif c == 'q'
            close(win)
        end
    end
    return dct
end
