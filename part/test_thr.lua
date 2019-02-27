-- Create an event
myEvent = event.create()

function ReadData()
    while(true) do
        myEvent:wait()
        print("Reading data...")
        thread.sleep(3)
        myEvent:done()
    end
end

function go()
    print("--- Start broadcast")
    myEvent:broadcast()
    print("--- End broadcast")
end


thread.start(ReadData)

-- Broadcast event
--myEvent:broadcast()