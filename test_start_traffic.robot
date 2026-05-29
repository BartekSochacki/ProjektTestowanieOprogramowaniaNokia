*** Settings ***
Documentation   Testy funkcjonalności rozpoczęcia przesyłania danych w symulatorze EPC.
Library         RequestsLibrary
Library         Collections

*** Variables ***
${BASE_URL}             http://localhost:8000
${VALID_UE_ID}          10
${SECOND_UE_ID}         20
${DEFAULT_BEARER}       9
${DODATKOWY_BEARER}     3
${VALID_SPEED_KBPS}     500
${ZERO_SPEED}           0
${NEG_SPEED}            -1
${OVER_LIMIT_SPEED}     200000
${PROTOCOL}             tcp
${NIEAKTYWNY_BEARER}    1

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

Start Traffic With Direction
    [Arguments]    ${ue_id}    ${bearer_id}    ${kbps}    ${direction}    ${protocol}=tcp
    &{body}=        Create Dictionary    protocol=${protocol}    kbps=${kbps}    direction=${direction}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Start Traffic Without Speed
    [Arguments]    ${ue_id}    ${bearer_id}    ${protocol}=tcp
    &{body}=        Create Dictionary    protocol=${protocol}
    ${response}=    POST On Session    epc    /ues/${ue_id}/bearers/${bearer_id}/traffic    json=${body}    expected_status=any
    RETURN    ${response}

Status Code Should Be
    [Arguments]    ${response}    ${expected}
    Should Be Equal As Integers    ${response.status_code}    ${expected}

Status Code Should Be Error
    [Arguments]    ${response}
    Should Be True    ${response.status_code} >= 400

*** Test Cases ***
TC01 Rozpoczecie Transferu DL Z Poprawnymi Parametrami
    [Documentation]    Transfer danych można rozpocząć dla aktywnego bearera z poprawnymi parametrami.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    Status Code Should Be    ${resp}    200

TC02 Rozpoczecie Transferu Bez Podania Szybkosci Zwraca Blad
    [Documentation]    Żądanie bez parametru kbps powinno zwrócić błąd.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic Without Speed    ${VALID_UE_ID}    ${DEFAULT_BEARER}
    Status Code Should Be Error    ${resp}

TC03 Rozpoczecie Transferu Na Nieaktywnym Bearerze Zwraca Blad
    [Documentation]    Próba rozpoczęcia transferu na bearerze który nie jest aktywny zwraca błąd.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${NIEAKTYWNY_BEARER}    ${VALID_SPEED_KBPS}
    Status Code Should Be Error    ${resp}

TC04 Rozpoczecie Transferu Bez UE ID Zwraca Blad
    [Documentation]    Żądanie bez UE ID w URL powinno zwrócić błąd.
    [Setup]    Setup API Session
    ${resp}=    Start Traffic    ${EMPTY}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}
    Status Code Should Be Error    ${resp}

TC05 Rozpoczecie Transferu Bez Bearer ID Zwraca Blad
    [Documentation]    Żądanie bez bearer ID w URL powinno zwrócić błąd.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${EMPTY}    ${VALID_SPEED_KBPS}
    Status Code Should Be Error    ${resp}

TC06 Rozpoczecie Transferu Z Zerowa Szybkoscia Zwraca Blad
    [Documentation]    Szybkość transferu = 0 nie powinna aktywować ruchu, oczekiwany błąd 400.
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${ZERO_SPEED}
    Status Code Should Be    ${resp}    400

TC07 Rozpoczecie Transferu Z Ujemna Szybkoscia Zwraca Blad
    [Documentation]    Szybkość transferu nie może być ujemna. Implementacja może nie walidować tej wartości.
    [Tags]    known-defect
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${NEG_SPEED}
    Status Code Should Be Error    ${resp}

TC08 Rozpoczecie Transferu Z Szybkoscia Powyzej Limitu Zwraca Blad
    [Documentation]    Łączny transfer DL nie może przekraczać 100 Mbps. Implementacja może nie walidować limitu.
    [Tags]    known-defect
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${OVER_LIMIT_SPEED}
    Status Code Should Be Error    ${resp}

TC09 Rozpoczecie Transferu W Kierunku UL Nie Powinno Byc Akceptowane
    [Documentation]    Transfer w kierunku UL nie powinien być akceptowany. Implementacja akceptuje UL (niezgodność ze specyfikacją).
    [Tags]    known-defect
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    ${resp}=    Start Traffic With Direction    ${VALID_UE_ID}    ${DEFAULT_BEARER}    ${VALID_SPEED_KBPS}    UL
    Status Code Should Be Error    ${resp}

TC10 Suma Transferow Na Dwoch Bearerach Nie Moze Przekraczac Limitu
    [Documentation]    Łączny transfer UE na wszystkich bearerach nie powinien przekraczać 100 Mbps. Implementacja nie waliduje limitu sumarycznego.
    [Tags]    known-defect
    [Setup]    Setup API Session
    Attach UE    ${VALID_UE_ID}
    Add Bearer    ${VALID_UE_ID}    ${DODATKOWY_BEARER}
    Start Traffic    ${VALID_UE_ID}    ${DEFAULT_BEARER}    60000
    ${resp}=    Start Traffic    ${VALID_UE_ID}    ${DODATKOWY_BEARER}    60000
    Status Code Should Be Error    ${resp}
