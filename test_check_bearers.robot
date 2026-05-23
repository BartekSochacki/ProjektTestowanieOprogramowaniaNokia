*** Settings ***
Documentation   Testy funkcjonalności sprawdzania podłączonych bearerów dla UE w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}          10
${DEFAULT_BEARER}       9
${DODATKOWY_BEARER}     3

*** Test Cases ***
1. Sprawdzenie dostepnych bearerow dla podlaczonego UE
    [Documentation]    Test sprawdza czy można odczytać listę aktualnie dostępnych bearerów dla podłączonego UE.
    Podlacz UE O ID    ${VALID_UE_ID}
    Sprawdz Liste Bearerow Dla UE    ${VALID_UE_ID}

2. Sprawdzenie bearerow po dodaniu dodatkowego bearera
    [Documentation]    Test weryfikuje czy po dodaniu nowego bearera lista dostępnych bearerów jest zaktualizowana.
    Podlacz UE O ID    ${VALID_UE_ID}
    Dodaj Bearer Dla UE    ${VALID_UE_ID}    ${DODATKOWY_BEARER}
    Sprawdz Czy UE Ma Przypisany Bearer    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    Sprawdz Czy UE Ma Przypisany Bearer    ${VALID_UE_ID}    ${DODATKOWY_BEARER}

*** Keywords ***
Podlacz UE O ID
    [Arguments]    ${ue_id}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}
    Status Should Be  200    ${response}

Dodaj Bearer Dla UE
    [Arguments]    ${ue_id}    ${bearer_id}
    ${body}=          Create Dictionary    bearer_id=${bearer_id}
    ${response}=      POST On Session      epc_simulator    /ues/${ue_id}/bearers    json=${body}
    Status Should Be  200    ${response}

Sprawdz Liste Bearerow Dla UE
    [Arguments]    ${ue_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${resp_json}    bearers
    ${bearers}=       Get Dictionary Keys    ${resp_json}[bearers]
    Should Not Be Empty    ${bearers}

Sprawdz Czy UE Ma Przypisany Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${bearer_id_str}=  Convert To String    ${bearer_id}
    Dictionary Should Contain Key    ${resp_json}[bearers]    ${bearer_id_str}

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
