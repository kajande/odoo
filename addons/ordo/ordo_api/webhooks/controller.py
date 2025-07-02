from . import meta

async def chat(question, user_id, reply_mode=None):
    SYSTEM="""
    Tu es un enseignant exceptionnel du système scolaire sénégalais, spécialisé dans une pédagogie accessible, ludique et 
    adaptée aux élèves de différents niveaux. Ton rôle est de répondre aux questions des élèves et d'expliquer les concepts de 
    manière claire, simple et terre à terre. Utilise des exemples pratiques et concrets pour rendre tes explications 
    intéressantes et faciles à comprendre. Tu es egalement un excellent marketeur de tes services au-pres de tes utilisateurs.
    Un de tes roles est egalement de convaincre tes utilisateurs a acheter tes services !
    Assures-toi de fournir des reponses toujours detaillees, claires et concises. Sois encourageant, bienveillant, et cherche 
    toujours à rendre les élèves curieux et confiants dans leur apprentissage. 
    Tu te base primordialement sur le contexte fourni et tu utilises les outils a ta disposition pour repondre aux question.
    Prends en compte le code promo s'il est present dans le message et appelle l'outil necessaire pour le traiter.
    """
    # latex_context = "document en latex pur sans commentaires"
    # question = question.replace('document', latex_context)\
    #     .replace('image', latex_context)\
    #     .replace('graphique', f'graphique dans un {latex_context}')\
    #     .replace('courbe', f'courbe dans un {latex_context}')\
    #     .replace('figure', f'figure dans un {latex_context}')
    # if reply_mode == 'latex':
    #     question += "\nRetourner le resultat complet dans un document en latex avec bien structure, sans commentaire au debut ni a la fin."
    #     # PDF RESPONSE
    #     user_id = user_id.replace('+', '')
    #     basepath = Path(f"documents/{user_id}")
    #     basepath.mkdir(parents=True, exist_ok=True)
    #     texpath = basepath/"kajande.tex"
    # else:
    #     question += "\nGarder la reponse assez courte et concise."

    model="gpt-4o-mini"
    tools = [get_document, company_info, payment_info, kajande.get_bmc, moderator.human_reply, 
            smartacus_controller.handle_password_reset_confirmation_message,
            smartacus_controller.request_payment,
            account.add_affiliate_child,
            handle_coupon_message,
        ]

    db_conn = await aiosqlite.connect("ts2_maths.db")  
    # Pass the database connection to AsyncSqliteSaver
    checkpointer = AsyncSqliteSaver(db_conn)
    agent = ReactAgent(system=SYSTEM, model=model, tools=tools, memory=checkpointer, thread_id=user_id)
    response_text = await agent.respond(question, output=None)
    # coupon = await agent.respond("Strip and return the coupon code from previous message")
    # import ipdb;ipdb.set_trace()
    if not response_text:
        response_text = agent.output
    # print(f"\n{response_text}\n")
    response_url = None
    # fully handle latex responses
    if Document.contains_latex(response_text) or len(response_text) >= 1600:
        question = LATEX_PROMPT.replace('response', response_text)
        response_text = await agent.respond(question, output=None)
        if not response_text:
            response_text = agent.output
        # Extract the latex block:
        if not Document.is_latex_structured(response_text):
            response_text = Document.extract_latex(response_text)
        # PDF RESPONSE
        response_url = await Document.tex2image(response_text, user_id)
        response_text = await agent.respond(f"Retourne en moins de 5 mots le titre du contenu de ce text.")
    await db_conn.close()
    return response_text, response_url

async def welcome_user(phone_number, message=None):
    message = f"""
Welcome to our great app. Is this your number: {phone_number} ?
    """
    await meta.send_message(phone_number, message)

async def handle_simple_message(message, sender_phone, media_urls=None, reply_function=chat, **reply_args):
    return "Handle simple message"

async def handle_media_message(message, from_number, media_id, media_type='image', reply_function=chat):
    return "Handle media message"
