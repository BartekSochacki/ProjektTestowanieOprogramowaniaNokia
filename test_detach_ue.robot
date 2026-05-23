*** Settings ***
Documentation   Testy funkcjonalności odłączania UE od sieci (detach) w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}          10
${NIEPODLACZONY_UE_ID}  99

*** Test Cases ***
1. Odlaczenie podlaczonego UE od sieci
    [Documentation]    Test sprawdza czy podłączone UE może zostać poprawnie odłączone od sieci.
    Podlacz UE O ID    ${VALID_UE_ID}
    Odlacz UE Od Sieci    ${VALID_UE_ID}
    Sprawdz Czy UE Nie Istnieje Na Liscie Podlaczonych    ${VALID_UE_ID}

2. Proba odlaczenia UE ktore nie jest podlaczone do sieci
    [Documentation]    Test weryfikuje czy próba odłączenia UE które nie jest podłączone zwraca odpowiedni błąd.
    Proba Odlaczenia Niepodlaczonego UE Powinna Zwrocic Blad    ${NIEPODLACZONY_UE_ID}

*** Keywords ***
Podlacz UE O ID
    [Arguments]    ${ue_id}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}
    Status Should Be  200    ${response}

Odlacz UE Od Sieci
    [Arguments]    ${ue_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}

Sprawdz Czy UE Nie Istnieje Na Liscie Podlaczonych
    [Arguments]    ${ue_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Proba Odlaczenia Niepodlaczonego UE Powinna Zwrocic Blad
    [Arguments]    ${ue_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
