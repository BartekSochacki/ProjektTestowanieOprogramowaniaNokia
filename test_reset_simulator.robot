*** Settings ***
Documentation   Testy funkcjonalności resetowania symulatora EPC do stanu początkowego.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions

*** Variables ***
${VALID_UE_ID}          10
${DEFAULT_BEARER}       9
${VALID_SPEED_KBPS}     500
${PROTOCOL}             tcp

*** Test Cases ***
1. Zresetowanie symulatora przywraca stan poczatkowy
    [Documentation]    Test sprawdza czy po zresetowaniu symulatora wszystkie podłączone UE zostają usunięte i symulator wraca do stanu początkowego.
    Podlacz UE O ID    ${VALID_UE_ID}
    Sprawdz Czy UE Jest Na Liscie Podlaczonych    ${VALID_UE_ID}
    Zresetuj Symulator
    Sprawdz Czy Lista Podlaczonych UE Jest Pusta

*** Keywords ***
Podlacz UE O ID
    [Arguments]    ${ue_id}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}
    Status Should Be  200    ${response}

Sprawdz Czy UE Jest Na Liscie Podlaczonych
    [Arguments]    ${ue_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}

Zresetuj Symulator
    ${response}=      POST On Session      epc_simulator    /reset
    Status Should Be  200    ${response}

Sprawdz Czy Lista Podlaczonych UE Jest Pusta
    ${response}=      GET On Session    epc_simulator    /ues
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${ues_list}=      Set Variable    ${resp_json}[ues]
    Should Be Empty    ${ues_list}
