*** Settings ***
Documentation   Testy funkcjonalności sprawdzania aktualnego transferu danych w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    epc_simulator    http://localhost:8000
Suite Teardown  Delete All Sessions
Test Teardown   Reset Emulatora

*** Variables ***
${VALID_UE_ID}          10
${DEFAULT_BEARER}       9
${VALID_SPEED_KBPS}     500
${PROTOCOL}             tcp

*** Test Cases ***
1. Sprawdzenie transferu dla pojedynczego bearera w ramach UE
    [Documentation]    Test sprawdza czy można odczytać aktualne statystyki transferu dla konkretnego bearera w ramach podłączonego UE.
    Podlacz UE O ID    ${VALID_UE_ID}
    Rozpocznij Transfer Danych Dla UE I Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${PROTOCOL}    ${VALID_SPEED_KBPS}
    Sprawdz Transfer Dla Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}

2. Sprawdzenie sumarycznego transferu dla wszystkich bearerow UE
    [Documentation]    Test sprawdza czy można odczytać sumaryczne statystyki transferu dla wszystkich bearerów danego UE.
    Podlacz UE O ID    ${VALID_UE_ID}
    Rozpocznij Transfer Danych Dla UE I Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${PROTOCOL}    ${VALID_SPEED_KBPS}
    Sprawdz Sumaryczny Transfer Dla UE    ${VALID_UE_ID}

3. Domyslna jednostka transferu to kbps
    [Documentation]    Test weryfikuje czy domyślną jednostką zwracaną w statystykach transferu jest kbps (bps w odpowiedzi API).
    Podlacz UE O ID    ${VALID_UE_ID}
    Rozpocznij Transfer Danych Dla UE I Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${PROTOCOL}    ${VALID_SPEED_KBPS}
    Sprawdz Czy Statystyki Transferu Zawieraja Jednostke Bps    ${VALID_UE_ID}    ${DEFAULT_BEARER}

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

Sprawdz Transfer Dla Bearera
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${resp_json}    tx_bps
    Dictionary Should Contain Key    ${resp_json}    rx_bps

Sprawdz Sumaryczny Transfer Dla UE
    [Arguments]    ${ue_id}
    ${params}=        Create Dictionary    ue_id=${ue_id}    include_details=true
    ${response}=      GET On Session    epc_simulator    /ues/stats    params=${params}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${resp_json}    total_tx_bps
    Dictionary Should Contain Key    ${resp_json}    total_rx_bps

Sprawdz Czy Statystyki Transferu Zawieraja Jednostke Bps
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    Dictionary Should Contain Key    ${resp_json}    tx_bps
    Dictionary Should Contain Key    ${resp_json}    rx_bps
    Dictionary Should Contain Key    ${resp_json}    target_bps

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
