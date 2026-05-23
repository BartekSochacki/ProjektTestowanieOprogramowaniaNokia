*** Settings ***
Documentation   Testy funkcjonalności rozpoczęcia przesyłania danych w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}          10
${DEFAULT_BEARER}       9
${VALID_SPEED_KBPS}     500
${INVALID_PROTOCOL}     invalid
${PROTOCOL}             tcp

*** Test Cases ***
1. Rozpoczecie przesylania danych w kierunku DL z poprawnymi parametrami
    [Documentation]    Test sprawdza czy można rozpocząć transfer danych DL podając poprawną szybkość, UE ID oraz bearer ID.
    Podlacz UE O ID    ${VALID_UE_ID}
    Rozpocznij Transfer Danych Dla UE I Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${PROTOCOL}    ${VALID_SPEED_KBPS}

2. Proba rozpoczecia transferu z szybkoscia spoza zakresu
    [Documentation]    Test weryfikuje czy podanie szybkości transferu spoza dozwolonego zakresu powoduje wyświetlenie błędu.
    Podlacz UE O ID    ${VALID_UE_ID}
    Proba Rozpoczecia Transferu Bez Podania Szybkosci Powinna Zwrocic Blad    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${INVALID_PROTOCOL}

3. Proba rozpoczecia transferu na nieaktywnym bearerze
    [Documentation]    Test weryfikuje czy próba rozpoczęcia transferu na bearerze który nie jest aktywny zwraca błąd.
    Podlacz UE O ID    ${VALID_UE_ID}
    ${nieaktywny_bearer}=    Set Variable    1
    Proba Rozpoczecia Transferu Na Nieaktywnym Bearerze Powinna Zwrocic Blad    ${VALID_UE_ID}    ${nieaktywny_bearer}    ${PROTOCOL}    ${VALID_SPEED_KBPS}

*** Keywords ***
Podlacz UE O ID
    [Arguments]    ${ue_id}
    ${body}=          Create Dictionary    ue_id=${ue_id}
    ${response}=      POST On Session      epc_simulator    /ues    json=${body}
    Status Should Be  200    ${response}

Rozpocznij Transfer Danych Dla UE I Bearera
    [Arguments]    ${ue_id}    ${bearer_id}    ${protocol}    ${kbps}
    ${body}=          Create Dictionary    protocol=${protocol}    kbps=${kbps}
    ${response}=      POST On Session      epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}
    Status Should Be  200    ${response}

Proba Rozpoczecia Transferu Bez Podania Szybkosci Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}    ${protocol}
    ${body}=          Create Dictionary    protocol=${protocol}
    ${response}=      POST On Session      epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Proba Rozpoczecia Transferu Na Nieaktywnym Bearerze Powinna Zwrocic Blad
    [Arguments]    ${ue_id}    ${bearer_id}    ${protocol}    ${kbps}
    ${body}=          Create Dictionary    protocol=${protocol}    kbps=${kbps}
    ${response}=      POST On Session      epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    Should Not Be Equal As Strings    ${response.status_code}    200

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
