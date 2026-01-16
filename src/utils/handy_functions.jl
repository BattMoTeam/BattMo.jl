
function get_component_list(model::IntercalationBattery;
	include_current_collectors = true,
	include_electrolyte = true,
	include_separator = true)

	if include_current_collectors

		if include_electrolyte

			if include_separator
				components = ["NegativeElectrodeCurrentCollector",
					"NegativeElectrodeActiveMaterial",
					"Separator",
					"PositiveElectrodeActiveMaterial",
					"PositiveElectrodeCurrentCollector",
					"Electrolyte"]
			else
				components = ["NegativeElectrodeCurrentCollector",
					"NegativeElectrodeActiveMaterial",
					"PositiveElectrodeActiveMaterial",
					"PositiveElectrodeCurrentCollector",
					"Electrolyte"]

			end

		else
			if include_separator

				components = ["NegativeElectrodeCurrentCollector",
					"NegativeElectrodeActiveMaterial",
					"Separator",
					"PositiveElectrodeActiveMaterial",
					"PositiveElectrodeCurrentCollector"]

			else
				components = ["NegativeElectrodeCurrentCollector",
					"NegativeElectrodeActiveMaterial",
					"PositiveElectrodeActiveMaterial",
					"PositiveElectrodeCurrentCollector"]
			end
		end
	else

		if include_electrolyte
			if include_separator
				components = [
					"NegativeElectrodeActiveMaterial",
					"Separator",
					"PositiveElectrodeActiveMaterial",
					"Electrolyte"]
			else
				components = [
					"NegativeElectrodeActiveMaterial",
					"PositiveElectrodeActiveMaterial",
					"Electrolyte"]

			end
		else
			if include_separator
				components = [
					"NegativeElectrodeActiveMaterial",
					"Separator",
					"PositiveElectrodeActiveMaterial"]
			else
				components = [
					"NegativeElectrodeActiveMaterial",
					"PositiveElectrodeActiveMaterial"]
			end
		end
	end

	return components

end
