*** Settings ***
Documentation   Testy funkcjonalności resetowania symulatora EPC do stanu początkowego.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}         http://localhost:8000
${VALID_UE_ID}      10
${DEFAULT_BEARER}   9
${VALID_SPEED_KBPS}     500
${PROTOCOL}             tcp

*** Keywords ***
Setup API Session
    Create Session    epc    ${BASE_URL}
    POST On Session    epc    /reset    expected_status=any

Attach UE
    [Arguments]    ${ue_id}
    &{body}=        Create Dictionary    ue_id=${ue_id}
    ${response}=    POST On Session    epc    /ues    json=${body}    expected_status=any
    RETURN    ${response}

Start Traffic
    [Arguments]    ${ue_id}    ${bearer_id}    ${kbps}    ${protocol}=tcp
    &{body}=        Create Dictionary    protocol=${protocol}    kbps=${kbps}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Reset Simulator
    ${response}=    POST On Session    epc    /reset    expected_status=any
    RETURN    ${response}

Get All UEs
    ${response}=    GET On Session    epc    /ues    expected_status=any
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
TC01 Reset Przywraca Stan Poczatkowy I Usuwa Wszystkie UE
    [Documentation]    Po resecie lista podłączonych UE jest pusta.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${ues_before}=    Get All UEs
    Should Not Be Empty    ${ues_before.json()}[ues]
    Reset Simulator
    ${ues_after}=    Get All UEs
    Status Code Should Be    ${ues_after}    200
    Should Be Empty    ${ues_after.json()}[ues]

TC02 Reset Usuwa UE Wraz Z Bearerami
    [Documentation]    Po resecie UE nie istnieje w systemie, co oznacza że bearery również są usunięte.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Reset Simulator
    ${state}=    Get UE State    ${VALID_UE_ID}
    Status Code Should Be Error    ${state}

TC03 Reset Zatrzymuje Aktywne Transfery
    [Documentation]    Po resecie UE z aktywnym transferem nie istnieje, co potwierdza zatrzymanie ruchu.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    Reset Simulator
    ${state}=    Get UE State    ${VALID_UE_ID}
    Status Code Should Be Error    ${state}

TC04 Wielokrotny Reset Jest Mozliwy
    [Documentation]    Symulator można zresetować wielokrotnie i każde wywołanie zwraca 200.
    [Setup]    Setup API Session
    ${r1}=    Reset Simulator
    Status Code Should Be    ${r1}    200
    ${r2}=    Reset Simulator
    Status Code Should Be    ${r2}    200
    ${r3}=    Reset Simulator
    Status Code Should Be    ${r3}    200
