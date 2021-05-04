do

SkynetIADSContact = {}
SkynetIADSContact = inheritsFrom(SkynetIADSAbstractDCSObjectWrapper)

SkynetIADSContact.CLIMB = "CLIMB"
SkynetIADSContact.DESCEND = "DESCEND"

function SkynetIADSContact:create(dcsRadarTarget, abstractRadarElementDetected)
	local instance = self:superClass():create(dcsRadarTarget.object)
	setmetatable(instance, self)
	self.__index = self
	instance.abstractRadarElementsDetected = {}
	table.insert(instance.abstractRadarElementsDetected, abstractRadarElementDetected)
	instance.firstContactTime = timer.getAbsTime()
	instance.lastTimeSeen = 0
	instance.dcsRadarTarget = dcsRadarTarget
	instance.position = instance.dcsObject:getPosition()
	instance.numOfTimesRefreshed = 0
	instance.speed = 0
	instance.isHARM = false
	instance.simpleAltitudeProfile = {}
	return instance
end

function SkynetIADSContact:setIsHARM(state)
	self.isHARM = state
end

function SkynetIADSContact:getMagneticHeading()
	if ( self:isExist() ) then
		return mist.utils.round(mist.utils.toDegree(mist.getHeading(self.dcsObject)))
	else
		return -1
	end
end

function SkynetIADSContact:getAbstractRadarElementsDetected()
	return self.abstractRadarElementsDetected
end

function SkynetIADSContact:isTypeKnown()
	return self.dcsRadarTarget.type
end

function SkynetIADSContact:isDistanceKnown()
	return self.dcsRadarTarget.distance
end

function SkynetIADSContact:getPosition()
	return self.position
end

function SkynetIADSContact:getGroundSpeedInKnots(decimals)
	if decimals == nil then
		decimals = 2
	end
	return mist.utils.round(self.speed, decimals)
end

function SkynetIADSContact:getHeightInFeetMSL()
	if self:isExist() then
		return mist.utils.round(mist.utils.metersToFeet(self.dcsObject:getPosition().p.y), 0)
	else
		return 0
	end
end

function SkynetIADSContact:getDesc()
	if self:isExist() then
		return self.dcsObject:getDesc()
	else
		return {}
	end
end

function SkynetIADSContact:getNumberOfTimesHitByRadar()
	return self.numOfTimesRefreshed
end

function SkynetIADSContact:refresh()
	self.numOfTimesRefreshed = self.numOfTimesRefreshed + 1
	if self:isExist() then
		local distance = mist.utils.metersToNM(mist.utils.get2DDist(self.position.p, self.dcsObject:getPosition().p))
		local timeDelta = (timer.getAbsTime() - self.lastTimeSeen)
		if timeDelta > 0 then
			local hours = timeDelta / 3600
			self.speed = (distance / hours)
			self:updateSimpleAltitudeProfile()
			self.position = self.dcsObject:getPosition()
		end 
	end
	self.lastTimeSeen = timer.getAbsTime()
end

function SkynetIADSContact:updateSimpleAltitudeProfile()
	local currentAltitude = self.dcsObject:getPosition().p.y
	
	local previousPath = ""
	if #self.simpleAltitudeProfile > 0 then
		previousPath = self.simpleAltitudeProfile[#self.simpleAltitudeProfile]
	end
	
	if self.position.p.y > currentAltitude and previousPath ~= SkynetIADSContact.DESCEND then
		table.insert(self.simpleAltitudeProfile, SkynetIADSContact.DESCEND)
	elseif self.position.p.y < currentAltitude and previousPath ~= SkynetIADSContact.CLIMB then
		table.insert(self.simpleAltitudeProfile, SkynetIADSContact.CLIMB)
	end
end

function SkynetIADSContact:getSimpleAltitudeProfile()
	return self.simpleAltitudeProfile
end

function SkynetIADSContact:getAge()
	return mist.utils.round(timer.getAbsTime() - self.lastTimeSeen)
end

end

