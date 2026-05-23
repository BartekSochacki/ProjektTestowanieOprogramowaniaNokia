*** Settings ***
Documentation   Testy funkcjonalności dodawania kanału transportowego (bearer) dla UE w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}              10
${VALID_BEARER_ID}          5
${OUT_OF_RANGE_BEARER_ID}   15
${DEFAULT_BEARER}           9

*** Test Cases ***
1. Dodanie dedykowanego bearera dla podlaczonego UE
    [Documentation]    Test sprawdza czy można dodać dedykowany bearer dla podłączonego UE podając UE ID oraz bearer ID.
    Podlacz UE O ID    ${VALID_UE_ID}
    Dodaj Bearer Dla UE    ${VALID_UE_ID}    ${VALID_BEARER_ID}
    Sprawdz Czy UE Ma Przypisany Bearer    ${VALID_UE_ID}    ${VALID_BEARER_ID}

2. Proba dodania bearera o ID spoza dozwolonego zakresu
    [Documentation]    Test weryfikuje czy podanie bearer ID spoza zakresu (1-9) powoduje wyświetlenie błędu.
    Podlacz UE O ID    ${VALID_UE_ID}
    Proba Dodania Bearera Spoza Zakresu Powinna Zwrocic Blad    ${VALID_UE_ID}    ${OUT_OF_RANGE_BEARER_ID}

3. Proba dodania bearera ktory juz zostal przypisany do UE
    [Documentation]    Test weryfikuje czy próba dodania bearera który już istnieje dla danego UE powoduje wyświetlenie błędu.
    Podlacz UE O ID    ${VALID_UE_ID}
    Dodaj Bearer Dla UE    ${VALID_UE_ID}    ${VALID_BEARER_ID}
    Proba Ponownego Dodania Istniejacego Bearera Powinna Zwrocic Blad    ${VALID_UE_ID}    ${VALID_BEARER_ID}

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

Sprawdz Czy UE Ma Przypisany Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${bearer_id_str}=  Convert To String    ${bearer_id}
    Dictionary Should Contain Key    ${resp_json}[bearers]    ${bearer_id_str}

Proba Dodania Bearera Spoza Zakresu Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}
    ${body}=          Create Dictionary    bearer_id=${bearer_id}
    ${response}=      POST On Session      epc_simulator    /ues/${ue_id}/bearers    json=${body}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Proba Ponownego Dodania Istniejacego Bearera Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}
    ${body}=          Create Dictionary    bearer_id=${bearer_id}
    ${response}=      POST On Session      epc_simulator    /ues/${ue_id}/bearers    json=${body}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
