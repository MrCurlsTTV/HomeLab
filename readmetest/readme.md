flowchart TD
  Start([Start])
  Internet{Internet?}
  Language[Select language, locale,\nkeyboard]
  Connect[Connect to internet]
  DeviceID[Obtain device ID]
  Profile{Get Autopilot\nprofile?}
  Glove{White glove\nkeystroke?}
  OOBE[Continue consumer OOBE]
  Autopilot{Is Autopilot?}
  JSON{JSON file\nexists?}
  Critical[Check for\ncritical Autopilot\nupdate]
  Update{Update\navailable?}
  Install[Install update,\nreboot]
  Deploy{Self-deploying,\nwhite glove,\npre-provisioned?}
  LangSelected{Language\nselected?}
  SetLang[Set language,\nlocale, keyboard]
  GoStart([Go to Start])

  Start --> Internet -->|Yes| Language --> Connect --> DeviceID --> Profile
  Profile -->|Yes| Glove -->|Yes| Critical
  Profile -->|No| OOBE
  Glove -->|No| OOBE
  OOBE --> Autopilot
  Autopilot -->|Yes| Critical
  Autopilot -->|No| JSON
  JSON -->|No| GoStart
  JSON -->|Yes| Critical
  Critical --> Update
  Update -->|Yes| Install --> GoStart
  Update -->|No| Deploy

  Deploy -->|No| LangSelected
  LangSelected -->|No| SetLang --> GoStart
  LangSelected -->|Yes| GoStart

  Deploy -->|Yes| TPM1[TPM attestation] --> AADJoin1[Azure AD auto join] --> MDM1[MDM enrollment] --> DeviceESP1[Device ESP] --> Done1([Done])

  Deploy -->|User-driven Azure AD?| AADJoin2[Azure AD join] --> MDM2[MDM enrollment] --> DeviceESP2[Device ESP] --> AADSign["Azure AD (auto) sign-in"] --> UserESP1[User ESP] --> Done2([Done])

  Deploy -->|User-driven AD DS?| AADJoin3[Azure AD join] --> MDM3[MDM enrollment] --> ODJReq1[ODJ request] --> ODJResp1[ODJ received and applied, reboot] --> DeviceESP3[Device ESP] --> ADDSLogin[AD DS sign-in] --> UserESP2[User ESP] --> Done3([Done])
