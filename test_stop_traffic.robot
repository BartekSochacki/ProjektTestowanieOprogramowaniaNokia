*** Settings ***
Documentation   Testy funkcjonalności zakończenia przesyłania danych w symulatorze EPC.
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
1. Zakonczenie transferu dla konkretnego bearera w ramach UE
    [Documentation]    Test sprawdza czy można zakończyć transfer danych dla poszczególnego bearera w ramach podłączonego UE.
    Podlacz UE O ID    ${VALID_UE_ID}
    Rozpocznij Transfer Danych Dla UE I Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${PROTOCOL}    ${VALID_SPEED_KBPS}
    Zakoncz Transfer Dla Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}

2. Zakonczenie transferu dla wszystkich bearerow w ramach UE
    [Documentation]    Test sprawdza czy można całkowicie zakończyć transfer danych dla wszystkich bearerów danego UE.
    Podlacz UE O ID    ${VALID_UE_ID}
    Rozpocznij Transfer Danych Dla UE I Bearera    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${PROTOCOL}    ${VALID_SPEED_KBPS}
    Zakoncz Transfer Dla Wszystkich Bearerow UE    ${VALID_UE_ID}

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

Zakoncz Transfer Dla Bearera
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=      DELETE On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic
    Status Should Be  200    ${response}

Zakoncz Transfer Dla Wszystkich Bearerow UE
    [Arguments]    ${ue_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${bearers}=       Get Dictionary Keys    ${resp_json}[bearers]
    FOR    ${bearer_id}    IN    @{bearers}
        ${del_response}=    DELETE On Session    epc_simulator    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    END
    Sprawdz Czy Wszystkie Bearery UE Sa Nieaktywne    ${ue_id}

Sprawdz Czy Wszystkie Bearery UE Sa Nieaktywne
    [Arguments]    ${ue_id}
    ${response}=      GET On Session    epc_simulator    /ues/${ue_id}
    Status Should Be  200    ${response}
    ${resp_json}=     Set Variable    ${response.json()}
    ${bearers}=       Get Dictionary Values    ${resp_json}[bearers]
    FOR    ${bearer}    IN    @{bearers}
        Should Not Be True    ${bearer}[active]
    END

Reset Emulatora
    ${response}=      POST On Session      epc_simulator    /reset    expected_status=any
    Status Should Be  200    ${response}
