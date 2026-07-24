Citizen.CreateThread(function()
    while true do
        local sleep = 1000

        if currentStatus == "inside" then
            local ped = PlayerPedId()

            if IsPedInAnyVehicle(ped, false) then
                sleep = 0

                if Config.AutoDeleteVehicle and IsControlJustPressed(0, 75) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    TaskLeaveVehicle(ped, veh, 0)

                    Citizen.CreateThread(function()
                        local timeout = 0

                        while IsPedInVehicle(ped, veh, false) and timeout < 100 do
                            timeout = timeout + 1
                            Citizen.Wait(10)
                        end

                        if DoesEntityExist(veh) then
                            NetworkRequestControlOfEntity(veh)
                            DeleteEntity(veh)
                        end
                    end)
                end
            else
                sleep = 200
            end
        end

        Citizen.Wait(sleep)
    end
end)
