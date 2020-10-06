class CfgPatches
{
	class morrigan
	{
		units[]={};
		weapons[]={};
		requiredAddons[]={};
		author="Loic Gasnier";
		authorUrl="https://analyse-innovation-solution.fr";
		url="https://analyse-innovation-solution.fr";
	};
};
class CfgFunctions
{
	class MGN
	{
		class MGN_Functions
		{
			class Startup
			{
				postInit=1;
				file="\morrigan\init.sqf";
				description="Initialisation";
			};
		};
	};
};
class cfgMods
{
	author="lga";
	timepacked="1509074123";
};
