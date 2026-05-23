*** Settings ***
Documentation   Testy funkcjonalności podłączania UE do symulatora EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}      10
${OUT_OF_RANGE_ID}  150
${DEFAULT_BEARER}   9

*** Test Cases ***
1. Podlaczenie UE do sieci z poprawnym ID
    [Documentation]    Test sprawdza czy można poprawnie podłączyć UE i czy otrzymuje on automatycznie domyślny bearer o ID 9.
    Podlacz UE O ID    ${VALID_UE_ID}
    Sprawdz Czy UE Ma Przypisany Bearer    ${VALID_UE_ID}    ${DEFAULT_BEARER}

2. Proba podlaczenia UE o id spoza dozwolonego zakresu
    [Documentation]    Test weryfikuje zachowanie symulatora gdy podane UE ID wykracza poza zakres (0-100).
    Proba Podlaczenia UE z nieprawidłowym ID    ${OUT_OF_RANGE_ID}    422

3. Proba ponownego podlaczenia juz podlaczonego UE
    [Documentation]    Test weryfikuje zachowanie symulatora gdy próbujemy podłączyć UE, które jest już podłączone.
    Podlacz UE O ID    ${VALID_UE_ID}
    Proba Ponownego Podlaczenia UE które ma już połączenie    ${VALID_UE_ID}

*** Keywords ***
Podlacz UE O ID
    [Arguments]    ${ue_id}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}
    Status Should Be  200    ${response}

Sprawdz Czy UE Ma Przypisany Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${bearer_id_str}=  Convert To String    ${bearer_id}
    Dictionary Should Contain Key     ${resp_json}[bearers]    ${bearer_id_str}

Proba Podlaczenia UE z nieprawidłowym ID
    [Arguments]    ${ue_id}    ${expected_status}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}    expected_status=any
    Status Should Be  ${expected_status}    ${response}

Proba Ponownego Podlaczenia UE które ma już połączenie
    [Arguments]    ${ue_id}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
