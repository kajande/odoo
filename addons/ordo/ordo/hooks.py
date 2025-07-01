import os
import logging
from odoo.tools import config

_logger = logging.getLogger(__name__)

def cleanup_attachments(env):
    try:
        _logger.info("⏩ Cleanup hook STARTING")
        db_name = env.cr.dbname
        _logger.info("⏩ DB NAME: ", db_name)
        filestore_base = os.path.join(config['data_dir'], 'filestore', db_name)
        
        _logger.info("🔍 Using filestore path: %s", filestore_base)
        
        if not os.path.exists(filestore_base):
            _logger.error("❌ Filestore directory %s does not exist!", filestore_base)
            return

        attachments = env['ir.attachment'].sudo().search([
            ('store_fname', '!=', False),
            ('store_fname', '!=', '')
        ])
        _logger.info("🔎 Found %d attachments to check", len(attachments))

        count = 0
        for attachment in attachments:
            try:
                rel_path = attachment.store_fname
                # Construct correct file path
                file_path = os.path.join(filestore_base, rel_path[:2], rel_path)

                if not os.path.isfile(file_path):
                    _logger.warning("Missing file for attachment %s (%s) -> deleting...", attachment.id, file_path)
                    attachment.unlink()
                    count += 1
            except Exception as e:
                _logger.error("Error processing attachment %s: %s", attachment.id, str(e))

        _logger.info("Cleanup completed. Deleted %d missing attachments.", count)
    except Exception as e:
        _logger.exception("Critical error in attachment cleanup: %s", str(e))
