*** Settings ***
Documentation   Testy funkcjonalności usuwania kanału transportowego (bearer) z UE w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}              10
${DEFAULT_BEARER}           9
${DEDYKOWANY_BEARER}        5
${OUT_OF_RANGE_BEARER_ID}   15
${NIEAKTYWNY_BEARER}        7

*** Test Cases ***
1. Usuniecie dedykowanego bearera z UE
    [Documentation]    Test sprawdza czy można usunąć dedykowany bearer z podłączonego UE podając UE ID oraz bearer ID.
    Podlacz UE O ID    ${VALID_UE_ID}
    Dodaj Bearer Dla UE    ${VALID_UE_ID}    ${DEDYKOWANY_BEARER}
    Usun Bearer Z UE    ${VALID_UE_ID}    ${DEDYKOWANY_BEARER}
    Sprawdz Czy UE Nie Ma Przypisanego Bearera    ${VALID_UE_ID}    ${DEDYKOWANY_BEARER}

2. Proba usuniecia bearera o ID spoza dozwolonego zakresu
    [Documentation]    Test weryfikuje czy podanie bearer ID spoza zakresu powoduje wyświetlenie błędu.
    Podlacz UE O ID    ${VALID_UE_ID}
    Proba Usuniecia Bearera Spoza Zakresu Powinna Zwrocic Blad    ${VALID_UE_ID}    ${OUT_OF_RANGE_BEARER_ID}

3. Proba usuniecia bearera ktory nie jest aktywny
    [Documentation]    Test weryfikuje czy próba usunięcia bearera który nie jest aktywny (nie został dodany) powoduje wyświetlenie błędu.
    Podlacz UE O ID    ${VALID_UE_ID}
    Proba Usuniecia Nieaktywnego Bearera Powinna Zwrocic Blad    ${VALID_UE_ID}    ${NIEAKTYWNY_BEARER}

4. Proba usuniecia domyslnego bearera
    [Documentation]    Test weryfikuje czy nie ma możliwości usunięcia domyślnego bearera (ID 9) — operacja powinna zwrócić błąd.
    Podlacz UE O ID    ${VALID_UE_ID}
    Proba Usuniecia Domyslnego Bearera Powinna Zwrocic Blad    ${VALID_UE_ID}    ${DEFAULT_BEARER}

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

Usun Bearer Z UE
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}
    Status Should Be  200    ${response}

Sprawdz Czy UE Nie Ma Przypisanego Bearera
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${bearer_id_str}=  Convert To String    ${bearer_id}
    Dictionary Should Not Contain Key    ${resp_json}[bearers]    ${bearer_id_str}

Proba Usuniecia Bearera Spoza Zakresu Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Proba Usuniecia Nieaktywnego Bearera Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Proba Usuniecia Domyslnego Bearera Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
