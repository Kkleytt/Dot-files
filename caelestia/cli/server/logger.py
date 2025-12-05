# utils.py
import logging
import sys
from pathlib import Path

def setup_logging(verbose: bool = False, log_file: str | None = None) -> logging.Logger:
    """Настраивает логгер с цветным выводом и опциональной записью в файл."""
    logger = logging.getLogger("Caelestia")
    logger.setLevel(logging.DEBUG if verbose else logging.INFO)

    # Убираем дублирующие хендлеры
    if logger.hasHandlers():
        logger.handlers.clear()

    # Формат с цветами для терминала
    class ColoredFormatter(logging.Formatter):
        COLORS = {
            "DEBUG": "\033[36m",    # Cyan
            "INFO": "\033[32m",     # Green
            "WARNING": "\033[33m",  # Yellow
            "ERROR": "\033[31m",    # Red
            "CRITICAL": "\033[35m", # Magenta
        }
        RESET = "\033[0m"

        def format(self, record):
            log_color = self.COLORS.get(record.levelname, "")
            record.levelname = f"{log_color}{record.levelname}{self.RESET}"
            return super().format(record)

    # Консольный хендлер
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(
        ColoredFormatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s", datefmt="%H:%M:%S")
    )
    logger.addHandler(console_handler)

    # Файловый хендлер (опционально)
    if log_file:
        file_handler = logging.FileHandler(Path(log_file).expanduser())
        file_handler.setFormatter(
            logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
        )
        logger.addHandler(file_handler)

    return logger