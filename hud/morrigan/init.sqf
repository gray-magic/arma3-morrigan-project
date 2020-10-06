//---------------------------INIT------------------------------------------------------
    //Numéro de version
private _rst = 'Morrigan' callExtension ['get_str_version',[]];
private _version = (_rst select 0);
systemChat format["Morrigan %1",_version];
systemChat format["Init.sqf %1","1.2.3.7"];

//Passe le compteur de soins à 0
'Morrigan' callExtension ['medic_init',[]];

//---------------------------EVENTS------------------------------------------------------
player addEventHandler ["Killed", {
    [player] call set_unit_state;
}];

player addEventHandler ["Dammaged", {
[player] call set_unit_state;
}];
    
//Compteur de personnages soignées
player addEventHandler ["HandleHeal", {
    private _rsth = 'Morrigan' callExtension ['medic_count',[]];
    private _heals = (_rsth select 0);
    systemChat format["%1",_heals];
    [player] call set_unit_state;
}];

player addEventHandler ["Reloaded", {
    [player] call set_unit_state;
}];

player addEventHandler ["InventoryClosed", {
    [player] call set_unit_state;
}];

player addEventHandler ["Respawn", {
    [player] call set_unit_state;
    [] call respawn;
}];


(findDisplay 46) displayAddEventHandler ["MouseButtonUp",   {
    [player] call set_unit_state;
}];

//Vue drône au chargement d'un partie
[getPos player, "Situation initiale", 200, 360, 90, 1, [
    //["\a3\ui_f\data\map\markers\nato\group_1.paa", [0,0.3,0.6,0.7], getPos player, 1, 1, 0, "VIP", 0]
], 0, true,4] spawn BIS_fnc_establishingShot;   

//---------------------------SPAWN------------------------------------------------------
[] spawn {
    [] call respawn;
};

respawn = { 
    missionNamespace setVariable ["morrigan_load",0];
    [] call set_add_actions;

    //Dessine l'indicateur du mod
    //ctrlDelete (uiNamespace getVariable "online_picture"); 
    with uiNamespace do  
    {  
        online_picture = findDisplay 46 ctrlCreate ["RscPicture", -1];  
        online_picture ctrlSetPosition [-0.7, 1.32,0.05,0.05];  
        online_picture ctrlSetText "morrigan\online.paa";  
        online_picture ctrlCommit 0;  
    };

    //Première synchronisation
    [player] call set_unit_state;

    // damage regions 
    // "head", "body", "hand_l", "hand_r", "leg_l", "leg_r"

    // damage types
    // "backblast", "bite", "bullet", "explosive", "falling", "grenade", "punch", "ropeburn", "shell", "stab", "unknown", "vehiclecrash"


    //Indicateurs 3D alliés/ennemis/distance/role
    addMissionEventHandler ['Draw3D', {
        if(!isnull player) then {   
            //Dans un véhicule
            private _vehicleNetId = -1;
            if(!(isNull objectParent player)) then { 
                _vehicleNetId = (vehicle _x) call BIS_fnc_netID;
            };

            if(_vehicleNetId == -1) then {
                //Ciblage allié 
                private _target = cursorTarget;  
                if (!isnull _target) then { 
                    if(alive _target && side _target == playerSide) then {
                        private _target_ico = "\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa";
                        private _label_target = "OTAN";
                        drawIcon3D [_target_ico,  [0,0.3,0.6,1] , (ASLToAGL eyePos _target), 1, 1, 0, _label_target , 2, 0.030, 'RobotoCondensed','center',true];
                    };
                };

                //Mise en évidence des ennemis détéctés dans un rayon de Xm avec icone durée de vie de l'indicateur par rapport à la dernière détéction 1 seconde 
                private _icon_size = 0.7;
                private _red_opfor = [1,0,0,0.7];
                private _radius = 200;
                private _maxage = 0.5;
                _target_ico = "\a3\ui_f\data\map\markers\nato\o_inf.paa"; //"\A3\ui_f\data\igui\cfg\simpleTasks\types\kill_ca.paa"; 
                 private _enemy_detected = player call BIS_fnc_enemyDetected;
                if(_enemy_detected) then {
                    _targets = player targets [true, _radius, [], _maxage]; 
                    {   
                        drawIcon3D [_target_ico, _red_opfor, ASLToAGL getPosASL _x, _icon_size, _icon_size, 0, "" , 2, 0.030, 'RobotoCondensed','center',true];
                    } forEach _targets;  
                };

                //Affichage des noms des membres de l'équipe et la flèche de direction + niveau de santé 
                private _view_leader = leader player;
                private _view_medic = player getUnitTrait "Medic";
                if(_view_leader == player) then {
                    _view_medic = true;
                };
            
                _fire_squad_members = units group player;
                {   
                    private _hide = false;
                    private _transparency = 0.5;
                    private _icon_size = 0.7;
                    private _color =[0,1,0,_transparency]; //blue
                    private _font_size = 0.030;
                    private _member_name = _x call BIS_fnc_getName; 
                    private _member_uid = getPlayerUID _x;
                    private _transco = "Morrigan" callExtension ["transcode_name",[_member_name,_member_uid]];
                    private _transco_name = (_transco select 0);
                    if(_transco_name != "") then {
                        _member_name = _transco_name;
                    };
                    private _member_health = (1 - damage _x) * 100;  
                    private _x_leader = leader _x;
                    private _x_medic = _x getUnitTrait "Medic"; 
                    private _icon = "\a3\ui_f\data\map\markers\nato\b_inf.paa";
                    private _life_state = lifeState _x;
                    
                    private _pos = ASLToAGL getPosASL _x;
                    private _extend_name = "";
                    private _distance = player distance _x;

                    private _line_color= [0,1,0,1];     //green
                    private _label = "";
       
                    if(_distance >= 200) then {
                        _line_color= [1,0.4,0,1];       //orange
                        _transparency = 0.35;
                    };

                    if(_distance >= 400) then {
                        _line_color= [1,0,0,1];         //rouge
                        _transparency = 0.25;
                    };

                    if(_distance >= 500) then {
                        _transparency = 0.1;
                    };

                    if(!_hide) then {

                        
                        if(_member_health <= 90) then {
                            _color = [0.85,0.85,0,_transparency];  
                        };

                        if(_member_health <= 50) then {
                            _color = [0.85,0.4,0,_transparency];  
                        };

                 
                        //Anti char
                        if (_x hasWeapon "launch_B_Titan_short_F" || _x hasWeapon "launch_I_Titan_short_F" || _x hasWeapon "launch_B_Titan_short_tna_F" || _x hasWeapon "launch_RPG7_F" || _x hasWeapon "launch_RPG32_F" || _x hasWeapon "launch_NLAW_F") then { 
                            _extend_name = "AC - ";
                            _icon = "\A3\ui_f\data\igui\cfg\weaponicons\AT_ca.paa"; 
                        };

                        //Charge de démolition
                        if ([_x, "DemoCharge_Remote_Mag"] call BIS_fnc_hasItem) then {
                            _extend_name ="EXPLO - ";
                            _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"; 
                        };

                        //Leader
                        if(_x_leader == _x) then {
                            _extend_name = "LEADER - ";
                            _icon = "a3\ui_f\data\gui\cfg\ranks\general_gs.paa";
                        };

                        //Medic
                        if(_x_medic) then {
                            _extend_name =  "MEDIC - ";
                            _icon = "\a3\ui_f\data\map\markers\nato\b_med.paa";
                        };        
            
                        //Blessé immobilisé indications !   
                        if(_view_medic && _life_state != "HEALTHY") then {
                            //Vivant 
                            if(_member_health > 0) then {
                                _color = [1,0,0,1];  
                                _icon_size = 0.9;
                                _icon_healh = "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa";
                                _label = "Blessé";

                                drawIcon3D [_icon_healh, _color, _pos , _icon_size, _icon_size, 0, format["%1 %2  - [%3 m]",_member_name,_label,_distance], 2, _font_size, 'RobotoCondensed','center',true];
                            }
                            else{
                                //Mort 
                                _transparency = 1;
                                _color = [0.5,0.5,0.5,_transparency];  
                                drawIcon3D ["", _color, _pos , 0, 0, 0, format["KIA - %1",_member_name], 2, _font_size, 'RobotoCondensed','center',false];
                            };
                        }
                        else{
                            //Vivant afficher 
                            if(_member_health > 0) then {
                                drawIcon3D [_icon, _color, _pos, _icon_size, _icon_size, 0, format["%2%1",_member_name,_extend_name], 2, _font_size, 'RobotoCondensed','center',true];
                            };
                        };
                    };
                } forEach _fire_squad_members;  
            
            }; //Test véhicule
        }; //Test null player
    }]; //DRAW 3D

}; //RESPAWN


//---------------------------FONCTIONS------------------------------------------------------ 

//Rajoute du grain suivant la distance 
update_grain = {
    params ["_target","_handle_effect"]; 
    private _distance = player distance _target;
    if(_distance == 0) then { 
        _distance = 1;
    };
    private _intensity = 0.62 + (_distance / 20000);
    private _sharpness = 1.25 - (_distance / 20000);
    private _grainSize = 2;
    
    _handle_effect ppEffectAdjust [_intensity, _sharpness, _grainSize, 0.75, 1.0, true];
	_handle_effect ppEffectCommit 0;
	ppEffectCommitted _handle_effect;
};

//Affiche la caméra d'une cible en plein écran 
head_cam_full_screen = { 
    params ["_target"]; 

    try{
        private _member_name = _target call BIS_fnc_getName; 
        private _unit_uid = getPlayerUID _target;
        private _transco = "Morrigan" callExtension ["transcode_name",[_member_name,_unit_uid]];
        private _transco_name = (_transco select 0) ;
        if(_transco_name != "") then {
            _member_name = _transco_name;
        };
           
        //Vision normal
        private _effect = 0;

        //Vision infrarouge amplificateur de lumière  
        if(currentVisionMode _target == 1) then {
            _effect = 1;
        };           
		
        //Création de la caméra PDV d'une autre entitée 
        _cam_operator = "camera" camCreate (ASLToAGL eyePos _target); 
        _cam_operator attachTo [_target, [0,1,0], "camera"]; 
        _cam_operator cameraEffect ["External","back"];
        _cam_operator camCommit 0;
        if(_effect == 1) then  { camUseNVG true; };

        _handle_effect = ppEffectCreate ["FilmGrain",2000];
        _handle_effect ppEffectEnable true;
        _handle_effect ppEffectAdjust [0.52, 1.25, 2, 0.75, 1.0, true];
        _handle_effect ppEffectCommit 0;
        missionNamespace setVariable ["_cam_operator",_cam_operator];
        missionNamespace setVariable ["_handle_effect",_handle_effect];
        
		 //Event de suppression de la caméra
        private _handle_keydown_id = (findDisplay 46) displayAddEventHandler ["KeyDown",   {
            //Supprime la caméra 
            _cam_operator = missionNamespace getVariable "_cam_operator";
            _cam_operator cameraEffect ["Terminate", "Back"];
            camDestroy _cam_operator;
            
            //Supprime l'effet 
            _handle_effect = missionNamespace getVariable "_handle_effect";
            _handle_effect ppEffectEnable false;
            ppEffectDestroy _handle_effect;
            _handle_effect = nil;
			_cam_operator = nil;
            
            //Supprime l'écoute du clavier 
            _handle_keydown_id = missionNamespace getVariable "_handle_keydown_id";
            findDisplay 46 displayRemoveEventHandler ["KeyDown",_handle_keydown_id ];
        }];
        
        //Sauvegarde l'id du handle
        missionNamespace setVariable ["_handle_keydown_id",_handle_keydown_id];

        waitUntil {
            if (isNull _handle_effect) exitWith { true }; 
			[_target,_handle_effect] call update_grain;
			ppEffectCommitted _handle_effect;
        };
    }
    catch{
        hint str _exception;
    };
};

// Fermer le HUD caméra 
close_head_cam_on_hud = {
    ctrlDelete (uiNamespace getVariable "camera_view_operator"); 
};

//Afficher la vue dans un conteneur du HUD
head_cam_on_hud = {
	params ["_target","_coord_x","_coord_y","_ratio"]; 	
    
    try{
        [] call close_head_cam_on_hud;       
        if(!isnull _target) then { 
            private _member_name = _target call BIS_fnc_getName; 
            private _distance = player distance _target;
            private _type = "";

            //Vision normal
            private _effect = 0;

            //Vision infrarouge amplificateur de lumière  
            if(currentVisionMode _target == 1) then {
                _effect = 1;
                _type = " IR";
            };           
          
            if(_distance <= 400) then {
                hint format["Caméra %2 opérateur : %1",_member_name,_type];
                
                with uiNamespace do {
                    private _morrigan_load = missionNamespace getVariable "morrigan_load";

                    if (_morrigan_load >= 1) then {
                        cam_operator cameraEffect ["terminate","back","rtt"];
                        camDestroy cam_operator;
                    };
                    
                    cam_operator = "camera" camCreate (ASLToAGL eyePos _target);
                    cam_operator attachTo [_target, [0,1,0], "camera"]; 
                    cam_operator cameraEffect ["internal","back","rtt"];
                    "rtt" setPiPEffect [_effect];
                    cam_operator camSetFov 0.4; 
                    cam_operator camCommit 0;
                    if(_effect == 1) then  { camUseNVG true; };
                    
                    camera_view_operator = findDisplay 46 ctrlCreate ["RscPicture", -1];
                    camera_view_operator ctrlSetPosition [_coord_x, _coord_y,_ratio,_ratio];
                    camera_view_operator ctrlCommit 0;
                    camera_view_operator ctrlSetText "#(argb,512,512,1)r2t(rtt,2.0)";

                    _morrigan_load = _morrigan_load +1;
                    missionNamespace setVariable ["morrigan_load",_morrigan_load];
                };

                
            }; 

            //Hors de portée pas de signal 
            if(_distance > 400) then {
                hint format["Aucun signal - opérateur : %1",_member_name];
            };
        };
    }
    catch{
        hint str _exception;
    };
};

/**Effectue une capture d'écran et la transfert à l'interface */
set_capture = {
   player sideChat "Photographie prise et transmise au QG";   
   screenshot "01.png";
};

/**Retourne l'état général d'une unité (matériel, munitions, vie, position, role) */
set_unit_state = {
    params ["_target_unit"];

     if(!isnull _target_unit) then {   
        private _unit_uid = getPlayerUID _target_unit;
        private _member_name = _target_unit call BIS_fnc_getName; 
        private _transco = "Morrigan" callExtension ["transcode_name",[_member_name,_unit_uid]];
        private _transco_name = (_transco select 0) ;
        if(_transco_name != "") then {
            _member_name = _transco_name;
        };
        private _member_health = (1 - damage _target_unit) * 100;  
        private  _group_name = groupId (group _target_unit);
        private _grid_coordinates = mapGridPosition _target_unit;
        private _position_x_y_z = getPos _target_unit;
        private _text_role = roleDescription _target_unit;
        private _weapon_name = ((configFile >> "CfgWeapons" >> currentWeapon _target_unit >> "displayName") call BIS_fnc_GetCfgData);
        private _magazine_name = currentMagazine _target_unit;
        private _magazines_list = magazinesAmmo _target_unit;

        private _is_medic = _target_unit getUnitTrait "medic";
        private _is_enginer = _target_unit getUnitTrait "engineer" ;
        private _is_explo = _target_unit getUnitTrait "explosiveSpecialist";
        private _is_leader = false;
        private _strenght_ac = "0";
        private _strenght_explo = "0";

        //Chef d'équipe
        if(leader _target_unit == _target_unit) then{
            _is_leader = true;
        };

        //AC lourd
        if ( _target_unit hasWeapon "launch_B_Titan_short_F" || _target_unit hasWeapon "launch_I_Titan_short_F" || _target_unit hasWeapon "launch_B_Titan_short_tna_F" ) then { 
            _strenght_ac = "100";
        };

        //AC léger
        if(_target_unit hasWeapon "launch_RPG7_F" || _target_unit hasWeapon "launch_RPG32_F" || _target_unit hasWeapon "launch_NLAW_F") then {
            _strenght_ac = "50";
        };

        //EXPLOSIFS léger
        if ([_target_unit, "DemoCharge_Remote_Mag"] call BIS_fnc_hasItem) then {
            _strenght_explo = "50";  
        };

        //EXPLOSIF lourd
        if ([_target_unit, "SatchelCharge_Remote_Mag"] call BIS_fnc_hasItem) then {
            _strenght_explo = "100";      
        };

        private _damages_part = getAllHitPointsDamage _target_unit;
        [
            ["hitface","hitneck","hithead","hitpelvis","hitabdomen","hitdiaphragm","hitchest","hitbody","hitarms","hithands","hitlegs","incapacitated"],
            ["face_hub","neck","head","pelvis","spine1","spine2","spine3","body","arms","hands","legs","body"],
            [0,0,0,0,0,0,0,0,0,0,0,0]
        ];

        private _daytime = daytime; // assuming daytime returns 1.66046
        private _hours = floor _daytime;											//  1
        private _minutes = floor ((_daytime - _hours) * 60);						// 39
        private _seconds = floor ((((_daytime - _hours) * 60) - _minutes) * 60);	
        private _str_daytime = format["%1:%2:%3",str _hours, str _minutes, str _seconds];

        private _state = getClientState;

        
      
        
        private _args = [
                            _member_name,                   //0
                            "0",                            //Distance
                            '',                             //Extend name 
                            _member_health,
                            _grid_coordinates,
                            _group_name,                    //5
                            _text_role,
                            _weapon_name,
                            _magazine_name,                 //8
                            _is_medic,
                            _is_enginer,
                            _is_explo,
                            _is_leader,                     //12
                            _strenght_ac,
                            _strenght_explo,                //14
                            _magazines_list,
                            _str_daytime,
                            _unit_uid,                       //17
                            _position_x_y_z,                 //18      
                            _state,                          //19
                            _damages_part                    //20   
                        ];
        'Morrigan' callExtension ['set_unit_state',_args];   
    };

}; //END set_unit_state

set_add_actions = {
	
    //removeAllActions player;
    //private _photo = player addAction ["<t color='#ffc000'>Photographie et transfert au QG</t>", { [] call set_capture } ] ;
	
    player addAction ["<t color='#c1ffc1'>Fermer le terminal de récéption des caméras</t>", { [] call close_head_cam_on_hud } ] ;
    private _cam_operator_members = units group player;
    {        
        if(_x != player) then {
            
            private  _member_name = _x call BIS_fnc_getName; 
            private _member_uid = getPlayerUID _x;
            private  _transco = "Morrigan" callExtension ["transcode_name",[_member_name,_member_uid]];
            private _transco_name = (_transco select 0) ;
            private  _label_name = _transco_name;
            if(_transco_name != "") then {
                _label_name = _member_name;
            };

            //Min_cam
            player addAction 
            [
                format["<t color='#c1ffc1'>Caméra de %1</t>",_label_name],
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    private _operator = (_arguments select 0) ;
                    [_operator,0.71,-0.405,0.6] call head_cam_on_hud;
                },
                [_x],
                0, 
                false, 
                true, 
                "",
                "true", 
                400,
                false,
                "",
                ""
            ];
        };
    } forEach _cam_operator_members;  
    
    // if(roleDescription player == "QG") then {
	// { 
    //     {
    //         if(side _x == playerSide) then {
    //             private  _member_name = _x call BIS_fnc_getName; 
    //             player addAction
    //             [
    //                 format["<t color='#c1ffc1'>Caméra de %1</t>",_member_name],
    //                 {
    //                     params ["_target", "_caller", "_actionId", "_arguments"];
    //                     private _operator = (_arguments select 0) ;
    //                     [_operator] call head_cam_full_screen;
    //                 },
    //                 [_x]
    //             ];
    //         };
    //     } 
    //     forEach playableUnits;
    // };
};
