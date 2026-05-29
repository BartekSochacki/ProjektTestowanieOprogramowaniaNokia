*** Settings ***
Documentation   Testy funkcjonalności zakończenia przesyłania danych w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}             http://localhost:8000
${VALID_UE_ID}          10
${DEFAULT_BEARER}       9
${DODATKOWY_BEARER}     3
${VALID_SPEED_KBPS}     500
${PROTOCOL}             tcp
${NIEPODLACZONY_UE_ID}  99

*** Keywords ***
Setup API Session
    Create Session    epc    ${BASE_URL}
    POST On Session    epc    /reset    expected_status=any

Attach UE
    [Arguments]    ${ue_id}
    &{body}=        Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Add Bearer
    [Arguments]    ${ue_id}    ${bearer_id}
    &{body}=        Create Dictionary    bearer_id=${bearer_id}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers    json=${body}    expected_status=any
    RETURN    ${response}

Start Traffic
    [Arguments]    ${ue_id}    ${bearer_id}    ${kbps}    ${protocol}=tcp
    &{body}=        Create Dictionary    protocol=${protocol}    kbps=${kbps}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Stop Traffic
    [Arguments]    ${ue_id}    ${bearer_id}
    ${response}=    DELETE On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    expected_status=any
    RETURN    ${response}

Get UE State
    [Arguments]    ${ue_id}
    ${response}=    GET On Session    epc    /ues/${ue_id}    expected_status=any
    RETURN    ${response}

Status Code Should Be
    [Arguments]    ${response}    ${expected}
    Should Be Equal As Integers    ${response.status_code}    ${expected}

Status Code Should Be Error
    [Arguments]    ${response}
    Should Be True    ${response.status_code} >= 400

*** Test Cases ***
TC01 Zakonczenie Transferu Dla Konkretnego Bearera
    [Documentation]    Transfer danych dla konkretnego bearera można poprawnie zakończyć.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    ${resp}=    Stop Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    Status Code Should Be    ${resp}    200

TC02 Zakonczenie Transferu Dla Wszystkich Bearerow UE
    [Documentation]    Transfer można zakończyć dla wszystkich bearerów jednego UE, każdy wraca do stanu nieaktywnego.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Add Bearer    ${VALID_UE_ID}    ${DODATKOWY_BEARER}
    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    Start Traffic    ${VALID_UE_ID}    ${DODATKOWY_BEARER}    ${VALID_SPEED_KBPS}
    ${state_before}=    Get UE State    ${VALID_UE_ID}
    ${bearers}=    Get Dictionary Keys    ${state_before.json()}[bearers]
    FOR    ${bearer_id}    IN    @{bearers}
        Stop Traffic    ${VALID_UE_ID}    ${bearer_id}
    END
    ${state_after}=    Get UE State    ${VALID_UE_ID}
    ${all_bearers}=    Get Dictionary Values    ${state_after.json()}[bearers]
    FOR    ${bearer}    IN    @{all_bearers}
        Should Not Be True    ${bearer}[active]
    END

TC03 Zatrzymanie Nieaktywnego Transferu Zwraca Blad
    [Documentation]    Próba zatrzymania transferu który nie jest aktywny powinna zwrócić błąd. API zwraca 200 (zachowanie idempotentne - niezgodność ze specyfikacją).
    [Tags]    known-defect
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Stop Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    Status Code Should Be Error    ${resp}

TC04 Po Zatrzymaniu Bearer Jest Nieaktywny
    [Documentation]    Po zatrzymaniu transferu bearer w stanie UE ma flagę active = False.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    Stop Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    ${state}=    Get UE State    ${VALID_UE_ID}
    Status Code Should Be    ${state}    200
    ${default_str}=    Convert To String    ${DEFAULT_BEARER}
    ${bearer}=    Get From Dictionary    ${state.json()}[bearers]    ${default_str}
    Should Not Be True    ${bearer}[active]

TC05 Zatrzymanie Transferu Dla Niepodlaczonego UE Zwraca Blad
    [Documentation]    Próba zatrzymania transferu dla UE które nie jest podłączone zwraca błąd.
    [Setup]    Setup API Session
    ${resp}=    Stop Traffic    ${NIEPODLACZONY_UE_ID}    ${DEFAULT_BEARER}
    Status Code Should Be Error    ${resp}

TC06 Zatrzymanie Transferu Na Jednym Bearerze Nie Wplywa Na Drugi
    [Documentation]    Zatrzymanie transferu na jednym bearerze nie dezaktywuje pozostałych bearerów UE.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Add Bearer    ${VALID_UE_ID}    ${DODATKOWY_BEARER}
    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    Start Traffic    ${VALID_UE_ID}    ${DODATKOWY_BEARER}    ${VALID_SPEED_KBPS}
    Stop Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    ${state}=    Get UE State    ${VALID_UE_ID}
    ${dodatkowy_str}=    Convert To String    ${DODATKOWY_BEARER}
    ${bearer}=    Get From Dictionary    ${state.json()}[bearers]    ${dodatkowy_str}
    Should Be True    ${bearer}[active]
